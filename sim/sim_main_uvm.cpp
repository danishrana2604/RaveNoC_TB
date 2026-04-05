#include "Vtb_top.h"
#include "verilated.h"
#include <memory>

int main(int argc, char** argv) {
    const std::unique_ptr<VerilatedContext> ctx{new VerilatedContext};
    ctx->commandArgs(argc, argv);

    const std::unique_ptr<Vtb_top> top{new Vtb_top{ctx.get(), "TOP"}};

    top->clk   = 0;
    top->rst_n = 0;

    // Run for max 10M time units
    for (uint64_t t = 0; t < 10000000ULL; t++) {
        ctx->timeInc(1);

        // Toggle clock every 5 units = 100MHz
        if (t % 5 == 0) top->clk = !top->clk;

        // Release reset after 200 time units
        if (t == 200) top->rst_n = 1;

        top->eval();

        if (ctx->gotFinish()) break;
    }

    top->final();
    return 0;
}
