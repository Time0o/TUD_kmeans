# directories ##################################################################

C_SRC_DIR=c/src
C_OBJ_DIR=c/obj
C_INCLUDE_DIR=c/include

CPP_SRC_DIR=cpp/src
CPP_OBJ_DIR=cpp/obj
CPP_INCLUDE_DIR=cpp/include

CONFIG_DIR=config
BENCHMARK_OUT_DIR=benchmarks
BUILD_DIR=build
IMAGE_DIR=images

# parameters ###################################################################

PROFILE_IMAGE=$(IMAGE_DIR)/profile_image.jpg
PROFILE_CLUSTERS=5

BENCHMARK_DIM_MIN=500
BENCHMARK_DIM_MAX=1500
BENCHMARK_DIM_STEP=250
BENCHMARK_CLUSTER_MIN=5
BENCHMARK_CLUSTER_MAX=5
BENCHMARK_CLUSTER_STEP=1
BENCHMARK_N_EXEC=100
BENCHMARK_PLOT=tool/plot.py

DEMO_IMAGE=$(IMAGE_DIR)/demo_image.jpg
DEMO_CLUSTERS=5
DEMO_RESULT_OUT=$(REPORT_RESOURCE_DIR)/demo_results.jpg

REPAIRTEST_IMAGE=$(IMAGE_DIR)/repairtest_image.bmp
REPAIRTEST_CLUSTERS=2
REPAIRTEST_RESULT_OUT=$(REPORT_RESOURCE_DIR)/repairtest_results.jpg

# compilation settings #########################################################

CC_C=gcc
CC_CUDA=nvcc
CC_CPP=g++

C_CFLAGS=-std=c99 -Wall -g -O3 -I$(C_INCLUDE_DIR) -I$(CONFIG_DIR) -fopenmp
CPP_CFLAGS=-std=c++11 -Wall -g -O0 -I$(CONFIG_DIR) -I$(C_INCLUDE_DIR) \
           -I$(CPP_INCLUDE_DIR) `pkg-config --cflags opencv`
CUDA_CFLAGS=-I$(CONFIG_DIR) -I$(C_INCLUDE_DIR)

LCV=`pkg-config --libs opencv`
LOMP=-fopenmp
LCUDA=-L/usr/local/cuda/lib64 -lcudart

# build sources ################################################################

all: $(BUILD_DIR)/demo $(BUILD_DIR)/profile $(BUILD_DIR)/benchmark

$(BUILD_DIR)/demo: $(CPP_OBJ_DIR)/kmeans_demo.o \
 $(C_OBJ_DIR)/kmeans.o $(C_OBJ_DIR)/kmeans_cuda.o \
 $(CPP_OBJ_DIR)/kmeans_wrapper.o
	$(CC_CPP) -o $@ $^ $(LCV) $(LOMP) $(LCUDA)

$(BUILD_DIR)/profile: $(CPP_OBJ_DIR)/kmeans_profile.o \
  $(C_OBJ_DIR)/kmeans_profile.o $(CPP_OBJ_DIR)/kmeans_wrapper.o
	$(CC_CPP) -o $@ $^ $(LCV) $(LOMP)

$(BUILD_DIR)/benchmark: $(CPP_OBJ_DIR)/kmeans_benchmark.o \
  $(C_OBJ_DIR)/kmeans.o $(C_OBJ_DIR)/kmeans_cuda.o \
  $(CPP_OBJ_DIR)/kmeans_wrapper.o
	$(CC_CPP) -o $@ $^ $(LCV) $(LOMP) $(LCUDA)

$(C_OBJ_DIR)/kmeans_cuda.o: $(C_SRC_DIR)/kmeans.cu \
  $(C_INCLUDE_DIR)/kmeans.h $(CONFIG_DIR)/kmeans_config.h
	$(CC_CUDA) -c -o $@ $< $(CUDA_CFLAGS)

$(C_OBJ_DIR)/kmeans_profile.o: $(C_SRC_DIR)/kmeans.c \
  $(C_INCLUDE_DIR)/kmeans.h $(CONFIG_DIR)/kmeans_config.h
	$(CC_C) -c -o $@ $< $(C_CFLAGS) -DPROFILE

$(C_OBJ_DIR)/%.o: $(C_SRC_DIR)/%.c \
  $(C_INCLUDE_DIR)/kmeans.h $(CONFIG_DIR)/kmeans_config.h
	$(CC_C) -c -o $@ $< $(C_CFLAGS)

$(CPP_OBJ_DIR)/%.o: $(CPP_SRC_DIR)/%.cc \
  $(C_INCLUDE_DIR)/kmeans.h $(CONFIG_DIR)/kmeans_config.h \
  $(CPP_INCLUDE_DIR)/kmeans_wrapper.h
	$(CC_CPP) -c -o $@ $< $(CPP_CFLAGS)

# PHONY rules ##################################################################

.PHONY: demo, profile, benchmark, clean

demo: $(BUILD_DIR)/demo $(DEMO_IMAGE)
	./$(BUILD_DIR)/demo $(DEMO_IMAGE) $(DEMO_CLUSTERS) $(DEMO_RESULT_OUT)

repairtest: $(BUILD_DIR)/demo $(REPAIRTEST_IMAGE)
	./$(BUILD_DIR)/demo $(REPAIRTEST_IMAGE) $(REPAIRTEST_CLUSTERS) \
	$(REPAIRTEST_RESULT_OUT)

profile: $(BUILD_DIR)/profile $(PROFILE_IMAGE)
	./$(BUILD_DIR)/profile $(PROFILE_IMAGE) $(PROFILE_CLUSTERS)

benchmark: $(BUILD_DIR)/benchmark $(BENCHMARK_PLOT)
	./$(BUILD_DIR)/benchmark \
	$(BENCHMARK_DIM_MIN) $(BENCHMARK_DIM_MAX) $(BENCHMARK_DIM_STEP) \
	$(BENCHMARK_CLUSTER_MIN) $(BENCHMARK_CLUSTER_MAX) $(BENCHMARK_CLUSTER_STEP) \
	$(BENCHMARK_N_EXEC) $(BENCHMARK_OUT_DIR)
	./$(BENCHMARK_PLOT) $(BENCHMARK_OUT_DIR)

clean:
	rm $(C_OBJ_DIR)/*.o 2> /dev/null || true
	rm $(CPP_OBJ_DIR)/*.o 2> /dev/null || true
	rm $(BUILD_DIR)/* 2> /dev/null || true
	rm $(REPORT_AUX_DIR)/* 2> /dev/null || true
	rm $(REPORT_PDF_DIR)/* 2> /dev/null || true
