## Phase-by-Phase Example

### F01: Explore raw data

```bash
make variant1 VARIANT=v001 RAW=./data/raw.csv CLEANING=basic NAN_VALUES='[-999999]'
make script1 VARIANT=v001
make check1 VARIANT=v001
make register1 VARIANT=v001
```

### F02: Build events dataset

```bash
make variant2 VARIANT=v202 PARENT=v001 STRATEGY=transitions BANDS='[10, 90]' NAN_MODE=discard
make script2 VARIANT=v202
make check2 VARIANT=v202
make register2 VARIANT=v202
```

### F03: Build windows dataset

```bash
make variant3 VARIANT=v302 PARENT=v202 OW=600 LT=100 PW=100 STRATEGY=synchro NAN_MODE=discard
make script3 VARIANT=v302
make check3 VARIANT=v302
make register3 VARIANT=v302
```

### F04: Create prediction targets

```bash
make variant4 VARIANT=v401 PARENT=v302 NAME=battery_overheat OPERATOR=OR EVENTS='["Battery_Active_Power_0_10-to-90_100,Battery_Active_Power_10_90-to-90_100"]'
make script4 VARIANT=v401
make check4 VARIANT=v401
make register4 VARIANT=v401
```

### F05: Train models

```bash
make variant5 VARIANT=v502 PARENT=v401 MODEL_FAMILY=cnn1d IMBALANCE_STRATEGY=rare_events
make script5 VARIANT=v502
make check5 VARIANT=v502
make register5 VARIANT=v502
```

Common F05 overrides include batch size, epochs, learning rate, embedding size, hidden units, dropout, AutoML, and evaluation split.

### F06: Quantize and package for edge

```bash
make variant6 VARIANT=v601 PARENT=v502
make script6 VARIANT=v601
make check6 VARIANT=v601
make register6 VARIANT=v601
```

F06 uses Docker for reproducible packaging in the default flow.

### F07: Validate a model on edge hardware

```bash
make variant7 VARIANT=v702 PARENT=v601 PLATFORM=esp32 MTI_MS=100 TIME_SCALE=0.01
make script7 VARIANT=v701
make check7 VARIANT=v701
make register7 VARIANT=v701
```

You can also run F07 step by step:

```bash
make script7-prepare-build VARIANT=v701
make script7-flash-run VARIANT=v701
make script7-post VARIANT=v701
```

### F08: Validate a multi-model edge system

```bash
make variant8 VARIANT=v801 PARENTS=v700,v703 PLATFORM=esp32 MTI_MS=100
make script8 VARIANT=v801
make check8 VARIANT=v801
make register8 VARIANT=v801
```

F08 also supports manual and ILP-based selection modes.
