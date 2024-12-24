// Testbench
`timescale 1 ps / 1 ps
module top_module_tb;
    // Signals
    logic        rst_n;
    logic        data_in;
    logic        valid_in;
    logic [14:0] seed;
    logic        ready_out;
    logic        valid_out;
    logic        serial_out;
    logic signed [15:0] i_out;    // Changed from x_out to i_out
    logic signed [15:0] q_out;    // Changed from y_out to q_out
    logic        [3:0] verify_leds;


    // Test Data - 3 blocks
    logic [95:0] input_data [0:5] = '{
        96'hACBCD2114DAE1577C6DBF4C9,
        96'hACBCD2114DAE1577C6DBF4C9,
        96'hACBCD2114DAE1577C6DBF4C9,
        96'hACBCD2114DAE1577C6DBF4C9,
        96'hACBCD2114DAE1577C6DBF4C9,
        96'hACBCD2114DAE1577C6DBF4C9
    };

    integer bit_index;
    integer block_index;

    logic clk_ref;

    // Capture arrays for outputs
    logic [191:0] captured_serial_data;
    integer serial_counter;

    // Arrays to store I/Q outputs
    logic signed [15:0] captured_i_data[$];  // Queue to store I values
    logic signed [15:0] captured_q_data[$];  // Queue to store Q values

    // DUT instantiation
    top_module dut (
        .clk_ref(clk_ref),
        .rst_n(rst_n),
        .data_in(data_in),
        .valid_in(valid_in),
        .seed(seed),
        .ready_out(ready_out),
        .valid_out(valid_out),
        .serial_out(serial_out),
        .i_out(i_out),            // Changed from x_out to i_out
        .q_out(q_out),            // Changed from y_out to q_out
        .verify_leds(verify_leds)
    );

    // // Clock generation - 50MHz and 100MHz
    always #10000 clk_ref = ~clk_ref;  // 50MHz (20ns period)
    // always #5000 clk_ref = ~clk_ref; // 100MHz (10ns period)

    // Monitor serial output
    always @(posedge clk_ref) begin
        if (serial_counter < 192 && !rst_n) begin
            captured_serial_data[serial_counter] <= serial_out;
            serial_counter <= serial_counter + 1;
        end
    end

    // Monitor I/Q outputs
    always @(posedge clk_ref) begin
        if (valid_out) begin
            captured_i_data.push_back(i_out);
            captured_q_data.push_back(q_out);
        end
    end

     // Monitor verification LEDs
    always @(verify_leds) begin
        if (verify_leds[0]) $display("Time=%0t: PRBS verification PASSED", $time);
        if (verify_leds[1]) $display("Time=%0t: FEC verification PASSED", $time);
        if (verify_leds[2]) $display("Time=%0t: Interleaver verification PASSED", $time);
        if (verify_leds[3]) $display("Time=%0t: Modulator verification PASSED", $time);
    end

    // Test procedure
    initial begin
        // Initialize signals
        clk_ref = 0;
        clk_ref = 0;
        rst_n = 0;
        data_in = 0;
        valid_in = 0;
        seed = 15'b011011100010101;
        bit_index = 0;
        block_index = 0;
        serial_counter = 0;

        // Reset the DUT
        #25000 rst_n = 1;
        @(posedge clk_ref);

        // Process all blocks
        for (block_index = 0; block_index < 6; block_index++) begin
            // Process each bit in the current block
            for (bit_index = 95; bit_index >= 0; bit_index--) begin
                @(posedge clk_ref);
                data_in <= input_data[block_index][bit_index];
                valid_in <= 1;

                // Wait until ready
                while (!ready_out) @(posedge clk_ref);
                if (verify_leds != 0) begin
                    $display("Time=%0t: Current verification status: %b", $time, verify_leds);
                end
            end

            // Gap between blocks
            @(posedge clk_ref);
            valid_in <= 0;
        end

        @(posedge clk_ref);
        valid_in <= 0;  

        // Add some cycles after last block
        repeat(500) @(posedge clk_ref);

        
        // Check final verification status
        $display("\nFinal Verification Status:");
        $display("PRBS Verify: %s", verify_leds[0] ? "PASS" : "FAIL");
        $display("FEC Verify: %s", verify_leds[1] ? "PASS" : "FAIL");
        $display("Interleaver Verify: %s", verify_leds[2] ? "PASS" : "FAIL");
        $display("Modulator Verify: %s", verify_leds[3] ? "PASS" : "FAIL");

        if (verify_leds === 4'b1111) begin
            $display("\nALL VERIFICATIONS PASSED!");
        end else begin
            $display("\nSOME VERIFICATIONS FAILED!");
        end

        
        $finish;
    end

    // Additional monitoring
    always @(posedge clk_ref) begin
        if (valid_in && ready_out) begin
            $display("Time=%0t: Sending bit %0d = %b", $time, bit_index, data_in);
        end
    end

    // Modulator output monitoring
    always @(posedge clk_ref) begin
        if (valid_out) begin
            $display("Time=%0t: Modulator I=%0d, Q=%0d", $time, i_out, q_out);
        end
    end

endmodule