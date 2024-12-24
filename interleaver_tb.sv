`timescale 1ps/1ps
module tb_interleaver();

    // Test signals
    logic clk;
    logic reset;
    logic input_data = 1'b0;    // Changed from data_in_serial
    logic data_valid = 1'b0;
    logic ready_in = 1'b1;     
    logic output_data;          // Changed from data_out_a/b to single output
    logic valid_out;
    logic ready_out;
    logic [8:0] address_a;
    logic [8:0] address_b;
    
    // Test data
    logic [0:191] out_expected = 192'h4B047DFA42F2A5D5F61C021A5851E9A309A24FD58086BD1E;
    logic [0:191] data_in_const = 192'h2833E48D392026D5B6DC5E4AF47ADD29494B6C89151348CA;

    // Test statistics
    int output_counter [3];
    int error_counter [3];
    int current_block;
    int total_outputs;
    int total_errors;

    // DUT instantiation
    interleaver dut (
        .clk(clk),
        .reset(reset),
        .input_data(input_data),     // Updated port name
        .data_valid(data_valid),
        .ready_in(ready_in),
        .output_data(output_data),   // Updated to single output
        .valid_out(valid_out),
        .ready_out(ready_out)
    );

    // Clock generation
    always begin
        #5 clk = ~clk;
    end

    // Task for initialization
    task initialize();
        clk = 0;
        reset = 1;
        data_valid = 0;
        input_data = 0;
        ready_in = 0;
        current_block = 0;
        total_outputs = 0;
        total_errors = 0;
        for (int i = 0; i < 3; i++) begin
            output_counter[i] = 0;
            error_counter[i] = 0;
        end
        $display("\n========================================================================");
        $display("                        Interleaver Test Results                         ");
        $display("========================================================================");
    endtask

    // Task for reset sequence
    task reset_sequence();
        repeat(2) @(negedge clk);
        reset = 0;
        ready_in = 1;
        repeat(2) @(posedge clk);
    endtask

    // Task for waiting until ready_out is asserted
    task wait_for_ready();
        while (!ready_out) @(posedge clk);
    endtask

    // Modified write data block task
    task write_data_block();
        int i;

        $display("\nStarting write phase for Block %0d...", current_block + 1);
        data_valid = 1;
        i = 0;

        repeat(192) begin  // Changed from 193 to 192 to match design
            wait_for_ready();
            input_data = data_in_const[i];
            @(posedge clk);
            i = (i + 1) % 192;
        end
    endtask

    // Task for printing table header
    task print_table_header();
        $display("\nBlock %0d Results:", current_block + 1);
        $display("| %-4s | %-8s | %-8s | %-9s |", 
            "Cnt", "Output", "Expected", "Addr");
        $display("----------------------------------------");
    endtask

    // Modified verify output task for single output
    task verify_output(input int cycle);
        if (valid_out) begin
            print_output_row(cycle);
            if (output_data !== out_expected[output_counter[current_block]]) begin
                error_counter[current_block]++;
                $display("Error at counter %0d: Expected: %b, Got: %b", 
                    output_counter[current_block], 
                    out_expected[output_counter[current_block]], 
                    output_data);
            end
            output_counter[current_block]++;
        end
    endtask

    // Modified print output row task for single output
    task print_output_row(input int cycle);
        $display("| %-4d | %-8b | %-8b | %-9h |",
            output_counter[current_block], output_data, 
            out_expected[output_counter[current_block]], 
            address_a);
    endtask

    // Task for printing block summary
    task print_block_summary();
        $display("\nBlock %0d Summary:", current_block + 1);
        $display("Total outputs verified: %0d", output_counter[current_block]);
        $display("Total errors: %0d", error_counter[current_block]);
        $display("Error rate: %0.2f%%", 
            (error_counter[current_block] * 100.0) / output_counter[current_block]);
        $display("----------------------------------------");
    endtask

    // Task for printing final test summary
    task print_final_summary();
        total_outputs = 0;
        total_errors = 0;
        
        $display("\n========================================================================");
        $display("Final Test Summary:");
        for (int i = 0; i < 2; i++) begin
            $display("Block %0d: Outputs=%0d, Errors=%0d, Error Rate=%0.2f%%",
                i + 1, output_counter[i], error_counter[i],
                (error_counter[i] * 100.0) / output_counter[i]);
            total_outputs += output_counter[i];
            total_errors += error_counter[i];
        end
        $display("\nOverall Statistics:");
        $display("Total outputs across all blocks: %0d", total_outputs);
        $display("Total errors across all blocks: %0d", total_errors);
        $display("Overall error rate: %0.2f%%", (total_errors * 100.0) / total_outputs);
        $display("========================================================================\n");
    endtask

    // Main test sequence
    initial begin
        initialize();
        reset_sequence();
        
        data_valid = 1;  // Set data_valid high at the start
        
        // Process two blocks
        for (int block = 0; block < 2; block++) begin
            current_block = block;
            print_table_header();
            
            write_data_block();

            // Keep input_data toggling during verification
            for (int i = 0; i < 192; i++) begin
                @(posedge clk);
                input_data = data_in_const[i % 192];
                verify_output(i);
            end

            print_block_summary();
            
            if (block < 1) begin
                reset_sequence();
            end
        end

        data_valid = 0;
        print_final_summary();
        $finish;
    end

endmodule