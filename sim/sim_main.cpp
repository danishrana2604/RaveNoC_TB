#include "Vtb_top.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include <memory>
#include <cstdio>

int main(int argc, char** argv) {
    const std::unique_ptr<VerilatedContext> ctx{new VerilatedContext};
    ctx->commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    const std::unique_ptr<Vtb_top> top{new Vtb_top{ctx.get(), "TOP"}};
    VerilatedFstC* tfp = new VerilatedFstC;
    top->trace(tfp, 99);
    tfp->open("sim.fst");

    // TX side init
    top->clk=0; top->rst_n=0;
    top->awvalid=0; top->awaddr=0; top->awlen=0;
    top->awsize=2;  top->awburst=1; top->awid=0;
    top->wvalid=0;  top->wdata=0; top->wstrb=0xF; top->wlast=0;
    top->bready=1;
    top->arvalid=0; top->araddr=0; top->arlen=0;
    top->arsize=2;  top->arburst=1; top->arid=0;
    top->rready=1;
    // RX side init � slave drives these
    top->rx_awready=1; top->rx_wready=1;
    top->rx_bvalid=0;  top->rx_bid=0; top->rx_bresp=0;
    top->rx_arready=1;
    top->rx_rvalid=0;  top->rx_rid=0; top->rx_rdata=0;
    top->rx_rresp=0;   top->rx_rlast=0;

    int cycle=0;

    auto tick = [&]() {
        top->clk=1; ctx->timeInc(5); top->eval(); tfp->dump(ctx->time()); cycle++;
        top->clk=0; ctx->timeInc(5); top->eval(); tfp->dump(ctx->time());
    };

    // Reset
    for (int i=0; i<20; i++) tick();
    top->rst_n=1; tick();

    printf("[cyc=%d] After reset\n", cycle);

    // -- WRITE to TX router [0][0] -------------------------------------
    // AW phase
    top->awvalid=1; top->awaddr=0x1000;
    top->awlen=0; top->awsize=2; top->awburst=1;
    for (int i=0; i<100; i++) {
        tick();
        if (top->awready) {
            printf("[cyc=%d] AW accepted\n", cycle);
            top->awvalid=0; break;
        }
    }

    // W phase � hold for 2 cycles
    top->wvalid=1; top->wdata=0xC0400001; // x=1,y=1,pkt_sz=1,payload=1
    top->wstrb=0xF; top->wlast=1;
    int w_cyc=-1;
    for (int i=0; i<100; i++) {
        tick();
        if (w_cyc<0 && top->wready) {
            w_cyc=cycle;
            printf("[cyc=%d] W accepted\n", cycle);
        }
        if (w_cyc>0 && cycle>w_cyc) {
            top->wvalid=0; top->wlast=0;
        }
        if (top->bvalid) {
            printf("[cyc=%d] B bresp=%d %s\n", cycle,
                   (int)top->bresp, top->bresp==0?"OKAY":"SLVERR");
            break;
        }
        if (w_cyc>0 && cycle>w_cyc+50) { printf("TIMEOUT B\n"); break; }
    }

    // Wait for packet to traverse NoC
    printf("Waiting for packet to reach RX router [1][1]...\n");
    for (int i=0; i<100; i++) tick();

    // -- READ from RX router [1][1] via noc_out_* ---------------------
    // Drive AR on noc_out_* side
    top->rx_arvalid=1; top->rx_araddr=0x2000; // AXI_RD_BFF_CHN(0)
    top->rx_arlen=0; top->rx_arsize=2; top->rx_arburst=1;
    top->rx_rready=1;

    printf("[cyc=%d] Driving AR on RX side (noc_out_*)\n", cycle);

    // Monitor noc_out_* signals from DUT
    for (int i=0; i<200; i++) {
        tick();
        printf("[cyc=%d] rx_ar=%d/%d rx_rv=%d rx_rdata=0x%08X\n",
               cycle, (int)top->rx_arvalid, (int)top->rx_arready,
               (int)top->rx_rvalid, (unsigned)top->rx_rdata);

        if (top->rx_arready) {
            printf("[cyc=%d] RX AR accepted\n", cycle);
            top->rx_arvalid=0;
        }
        if (top->rx_rvalid) {
            printf("[cyc=%d] RX R rdata=0x%08X rresp=%d rlast=%d\n",
                   cycle, (unsigned)top->rx_rdata,
                   (int)top->rx_rresp, (int)top->rx_rlast);
            printf(top->rx_rdata==0xC0400001 ?
                   "*** PASS ***\n" : "*** FAIL got 0x%08X ***\n",
                   (unsigned)top->rx_rdata);
            break;
        }
        if (i>150) { printf("TIMEOUT waiting RX R\n"); break; }
    }

    tfp->close();
    top->final();
    return 0;
}
