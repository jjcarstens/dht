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
#include "mock.h"
#define read_sensor(...) host_read(__VA_ARGS__);
#endif

static void decode_request_cmd_and_from(const char *req, int *req_index, char *cmd,
                                        const char **from, int *from_len)
{
    if (ei_decode_version(req, req_index, NULL) < 0)
        errx(EXIT_FAILURE, "Message version issue?");

    int arity;
    if (ei_decode_tuple_header(req, req_index, &arity) < 0 ||
            arity != 3)
        errx(EXIT_FAILURE, "expecting {cmd, from, args} tuple");

    if (ei_decode_atom(req, req_index, cmd) < 0)
        errx(EXIT_FAILURE, "expecting command atom");

    // Pull out the from tag so it can be returned for
    // the caller to use for replying
    int from_start_index = *req_index;
    *from = req + from_start_index;

    if (ei_skip_term(req, req_index) < 0)
        errx(EXIT_FAILURE, "failed to mark the from tag");

    *from_len = *req_index - from_start_index;
}

static void handle_request(const char *req, void *cookie)
{
    int req_index = sizeof(uint16_t);
    char cmd[MAXATOMLEN];
    const char *from;
    int from_len;

    decode_request_cmd_and_from(req, &req_index, cmd, &from, &from_len);

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

    // Add the from tag back for the caller to reply to
    ei_x_append_buf(&response, from, from_len);

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
