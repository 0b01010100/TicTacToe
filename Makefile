ASM = nasm
LD = gcc
LD_FLAGS = -mconsole
ASMFLAGS = -f win64
SRC = main.asm
OBJ = build/main.o
TARGET = bin/main.exe
LIBS = -lkernel32 -luser32 -lgdi32

all: $(TARGET)

$(TARGET): $(OBJ)
	@mkdir -p bin
	$(LD) $(OBJ) -o $(TARGET) $(LIBS) $(LD_FLAGS)

$(OBJ): $(SRC)
	@mkdir -p build
	$(ASM) $(ASMFLAGS) $(SRC) -o $(OBJ)

run: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(OBJ) $(TARGET)
