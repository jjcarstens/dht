#ifndef MOCK_H
#include "common_dht_read.h"

static int host_read(long sensor, long pin, float *humidity, float *temperature)
{
    *humidity = (float)rand() / (float)(RAND_MAX / 50);
    *temperature = (float)rand() / (float)(RAND_MAX / 30);
    return DHT_SUCCESS;
}
#endif
