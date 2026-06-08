module uart_tb;

    reg clk, rst;
    wire baud_tick;
    reg data_ready_tx;
    reg [7:0] data_in_tx;
    wire tx_serial, rx_serial;
    wire data_valid_rx;
    wire [7:0] data_out_rx;

    reg [7:0] test_data [0:4]; // memory array for test values

    parameter CLK_FREQ = 10000;
    parameter BAUD_RATE = 1000;

    // Baud generator
    baud_gen #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) baudgen (
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick)
    );

    // UART Transmitter
    uart_tx #(
        .DATA_WIDTH(8)
    ) dut_tx (
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick),
        .data_ready(data_ready_tx),
        .data_in(data_in_tx),
        .tx_serial(tx_serial)
    );

    // UART Receiver
    uart_rx #(
        .DATA_WIDTH(8)
    ) dut_rx (
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick),
        .rx_serial(rx_serial),
        .data_valid(data_valid_rx),
        .data_out(data_out_rx)
    );

    // Loopback connection
    assign rx_serial = tx_serial;

    // Clock generator (100 ns period → 10 MHz)
    initial begin
        clk = 0;
        forever #50 clk = ~clk;
    end

    // Stimulus
    integer i;
    initial begin
        rst = 1;
        data_ready_tx = 0;
        #200 rst = 0;

        // Load test data
        test_data[0] = 8'h43;
        test_data[1] = 8'h72;
        test_data[2] = 8'hA5;
        test_data[3] = 8'hE7;
        test_data[4] = 8'hF4;

        for (i = 0; i < 5; i = i + 1) begin
            @(posedge clk);
            data_in_tx = test_data[i];
            data_ready_tx = 1;
            #50;
            @(negedge baud_tick);
            data_ready_tx = 0;
            @(posedge data_valid_rx);
            #1000;
        end

        #10000 $finish;
    end

    // Monitor received data
    integer j;
    initial begin
        for (j = 0; j < 5; j = j + 1) begin
            @(posedge data_valid_rx);
            $display("Time: %t | Received: %h | Expected: %h",
                      $time, data_out_rx, test_data[j]);
            if (data_out_rx !== test_data[j]) begin
                $display("DATA MISMATCH at %t!", $time);
                $stop;
            end
        end
    end

    // Dumpfile for GTKWave
    initial begin
        $dumpfile("uart_tb.vcd");
        $dumpvars(0, uart_tb);
    end
endmodule