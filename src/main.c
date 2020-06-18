#include <err.h>
#include <poll.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "common_dht_read.h"
#include "erlcmd.h"

#define DEBUG
#ifdef DEBUG
#define debug(...) do { fprintf(stderr, __VA_ARGS__); fprintf(stderr, "\r\n"); } while(0)
#else
#define debug(...)
#endif

#define HOST 0
#define RPI 1
#define RPI2 2
#define BBB 3

#ifndef TARGET
#define TARGET HOST
#endif

static int host_read(long sensor, long pin, float *humidity, float *temperature)
{
    *humidity = (float)rand() / (float)(RAND_MAX / 50);
    *temperature = (float)rand() / (float)(RAND_MAX / 30);
    return DHT_SUCCESS;
}

#if TARGET == RPI
#include "pi_dht_read.h"
#define read_sensor(...) pi_dht_read(__VA_ARGS__);
#elif TARGET == RPI2
#include "pi_2_dht_read.h"
#define read_sensor(...) pi_2_dht_read(__VA_ARGS__);
#elif TARGET == BBB
#include "bbb_dht_read.h"
#define read_sensor(...) bbb_dht_read(__VA_ARGS__);
#else
#define read_sensor(...) host_read(__VA_ARGS__);
#endif

static void decode_request(const char *req, int *req_index, char *cmd, erlang_pid *pid,
                           erlang_ref *ref)
{
    if (ei_decode_version(req, req_index, NULL) < 0)
        errx(EXIT_FAILURE, "Message version issue?");

    int arity;
    if (ei_decode_tuple_header(req, req_index, &arity) < 0 ||
            arity != 3)
        errx(EXIT_FAILURE, "expecting {cmd, from, args} tuple");

    if (ei_decode_atom(req, req_index, cmd) < 0)
        errx(EXIT_FAILURE, "expecting command atom");

    int from_arity;
    if (ei_decode_tuple_header(req, req_index, &from_arity) < 0 ||
            from_arity != 2)
        errx(EXIT_FAILURE, "expecting a from tuple of {pid, ref}");

    if (ei_decode_pid(req, req_index, pid) < 0)
        errx(EXIT_FAILURE, "invalid from pid");

    if (ei_decode_ref(req, req_index, ref) < 0)
        errx(EXIT_FAILURE, "invalid from reference");
}

// static int read_sensor(long sensor, long pin, float *humidity, float *temperature)
// {
//   switch (TARGET) {
//   case HOST:
//     humidity = (float) rand()/(float)(RAND_MAX/50);
//     temperature = (float) rand()/(float)(RAND_MAX/30);
//     return DHT_SUCCESS;
//   case RPI:
//     return pi_dht_read(sensor, pin, humidity, temperature);
//   case RPI2:
//     return pi_2_dht_read(sensor, pin, humidity, temperature);
//   case BBBB:
//     return bbb_dht_read(sensor, pin, &humidity, &temperature);
//   }
// }


static void handle_request(const char *req, void *cookie)
{
    int req_index = sizeof(uint16_t);
    char cmd[MAXATOMLEN];
    erlang_pid pid;
    erlang_ref ref;

    decode_request(req, &req_index, cmd, &pid, &ref);

    ei_x_buff response;
    ei_x_new(&response);
    response.index += 2; // Leave room for the length
    ei_x_encode_version(&response);

    ei_x_encode_tuple_header(&response, 3);

    if (strcmp(cmd, "read") == 0) {
        int arity;
        if (ei_decode_tuple_header(req, &req_index, &arity) < 0 ||
                arity != 2)
            errx(EXIT_FAILURE, "expecting {pin, dht_sensor} tuple");

        long pin;
        long sensor;

        if (ei_decode_long(req, &req_index, &pin) < 0)
            errx(EXIT_FAILURE, "invalid pin");

        if (ei_decode_long(req, &req_index, &sensor) < 0)
            errx(EXIT_FAILURE, "invalid sensor");

        // debug("Reading DHT%li on pin %li", sensor, pin);

        float humidity = 0, temperature = 0;
        int result = read_sensor(sensor, pin, &humidity, &temperature);

        if (result == DHT_SUCCESS) {
            ei_x_encode_atom(&response, "ok");

            ei_x_encode_map_header(&response, 2);
            ei_x_encode_atom(&response, "temperature");
            ei_x_encode_double(&response, temperature);
            ei_x_encode_atom(&response, "humidity");
            ei_x_encode_double(&response, humidity);
        } else {
            ei_x_encode_atom(&response, "error");
            ei_x_encode_long(&response, result);
        }

    } else {
        ei_x_encode_atom(&response, "error");

        ei_x_encode_atom(&response, "unknown_command");
    }

    ei_x_encode_tuple_header(&response, 2);
    ei_x_encode_pid(&response, &pid);
    ei_x_encode_ref(&response, &ref);

    erlcmd_send(response.buff, response.index);
    ei_x_free(&response);
}

int main(int argc, char *argv[])
{
    debug("Starting DHT port");

    struct erlcmd handler;
    erlcmd_init(&handler, handle_request, "nomnom");

    for (;;) {
        struct pollfd fdset[1];

        fdset[0].fd = STDIN_FILENO;
        fdset[0].events = POLLIN;
        fdset[0].revents = 0;

        int rc = poll(fdset, 1, 50 /* ms */);

        if (rc < 0) {
            if (errno == EINTR)
                continue;

            err(EXIT_FAILURE, "poll");
        }

        if (fdset[0].revents & (POLLIN | POLLHUP))
            erlcmd_process(&handler);
    }
}
