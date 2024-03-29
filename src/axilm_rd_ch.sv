`ifndef MODELSIM
module axilm_rd_ch (
`else
module Vaxilm_rd_ch (
`endif
  input                 ARESETn,
  input                 ACLK,
  // Read Address Channel
  output  logic [31:0]  ARADDR,
  output  logic [2:0]   ARPROT,
  output  logic         ARVALID,
  input                 ARREADY,
  // Read Data Channel
  input         [31:0]  RDATA,
  input         [1:0]   RRESP,
  input                 RVALID,
  output  logic         RREADY,
  // Local Inerface
  input                 BUS_ENA,
  input         [3:0]   BUS_WSTB,
  input         [31:0]  BUS_ADDR,
  output  logic [31:0]  BUS_RDATA,
  output  logic [1:0]   BUS_RRESP
);
  enum logic [1:0] {
    IDLE          = 0,
    ARREADY_WAIT  = 1,
    RREADY_ASSERT = 2,
    RVALID_WAIT   = 3
  } state;

  assign ARPROT = 3'b000;

  logic usr_read_req;
  assign usr_read_req = BUS_ENA & ~(|BUS_WSTB);

  logic slv_addr_rsp;
  assign slv_addr_rsp = ARVALID & ARREADY;
  logic slv_data_rsp;
  assign slv_data_rsp = RVALID & RREADY;

  always_ff @(posedge ACLK or negedge ARESETn)
    if (~ARESETn) begin
      ARADDR <= 32'd0;
      ARVALID <= 1'b0;
      RREADY <= 1'b0;
      BUS_RDATA <= 32'd0;
      BUS_RRESP <= 2'b00;
    end else
      case (state)
        IDLE: begin
          if (usr_read_req) begin
            ARADDR <= BUS_ADDR;
            ARVALID <= 1'b1;
          end
          else
            ARVALID <= 1'b0;
          RREADY <= 1'b0;
        end
        ARREADY_WAIT:
          if (slv_addr_rsp) begin
            ARVALID <= 1'b0;
            RREADY <= 1'b1;
          end
        RREADY_ASSERT:
          if (slv_data_rsp) begin
            BUS_RDATA <= RDATA;
            BUS_RRESP <= RRESP;
            RREADY <= 1'b0;
          end
        RVALID_WAIT:
          if (slv_data_rsp) begin
            BUS_RDATA <= RDATA;
            BUS_RRESP <= RRESP;
            RREADY <= 1'b0;
          end
        default: begin
          ARADDR <= 32'd0;
          ARVALID <= 1'b0;
          RREADY <= 1'b0;
          BUS_RDATA <= 32'd0;
          BUS_RRESP <= 2'b00;
        end
      endcase

  always_ff @(posedge ACLK or negedge ARESETn)
    if (~ARESETn)
      state <= IDLE;
    else
      case (state)
        IDLE:
          if (usr_read_req)
            if (ARREADY)
              state <= RREADY_ASSERT;
            else
              state <= ARREADY_WAIT;
        ARREADY_WAIT:
          if (slv_addr_rsp)
            state <= RREADY_ASSERT;
        RREADY_ASSERT:
          if (RVALID)
            state <= IDLE;
          else
            state <= RVALID_WAIT;
        RVALID_WAIT:
          if (slv_data_rsp)
            state <= IDLE;
      endcase

endmodule
