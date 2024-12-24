module top_module (
    input  logic        clk_ref,
    input  logic        rst_n,
    input  logic        data_in,
    input  logic        valid_in,
    input  logic [14:0] seed,
    output logic        ready_out,
    output logic        valid_out,
    output logic        serial_out,
    output logic signed [15:0] i_out,    
    output logic signed [15:0] q_out,     
    output logic [3:0]  verify_leds    // LED outputs for verification

);
    
    // Internal connections
    logic prbs_data_out;
    logic prbs_valid_out;
    logic prbs_ready_out;
    logic fec_data_out;
    logic fec_valid_out;
    logic fec_ready_out;
    logic interleaver_ready_out;
    logic interleaver_data_out;
    logic interleaver_valid_out;
    logic modulator_ready_out;
    logic modulator_valid_out;
    logic clk_50MHz;
    logic clk_100MHz;

    // Verification signals
    logic [95:0]  prbs_capture;
    logic [191:0] fec_capture;
    logic [191:0] interleaver_capture;
    logic signed [15:0] i_samples[0:95];  // 96 I samples
    logic signed [15:0] q_samples[0:95];  // 96 Q samples
    logic [6:0]   prbs_counter;      // Counts to 96
    logic [7:0]   fec_counter;       // Counts to 192
    logic [7:0]   interleaver_counter; // Counts to 192
    logic [6:0]   modulator_counter;  // Counts to 96
    logic [3:0]   verification_status;

    // Constants for verification
    localparam [95:0]  EXPECTED_PRBS = 96'h558AC4A53A1724E163AC2BF9;
    localparam [191:0] EXPECTED_FEC = 192'h2833E48D392026D5B6DC5E4AF47ADD29494B6C89151348CA;
    localparam [191:0] EXPECTED_INTERLEAVER = 192'h4B047DFA42F2A5D5F61C021A5851E9A309A24FD58086BD1E;
    localparam signed [15:0] POS_707 = 16'sd11585;  // +0.707 in Q1.15 format
    localparam signed [15:0] NEG_707 = -16'sd11585; // -0.707 in Q1.15 format

    PLL pll_inst (
        .refclk(clk_ref),      
        .rst(~rst_n),          
        .outclk_0(clk_50MHz),     
        .outclk_1(clk_100MHz),    
        .locked(pll_locked)    
    );


    // PRBS instantiation
    prbs_randomizer prbs_inst (
        .clk(clk_50MHz),
        .rst_n(rst_n),
        .ready_in(fec_ready_out),
        .data_in(data_in),
        .valid_in(valid_in),
        .seed(seed),
        .data_out(prbs_data_out),
        .valid_out(prbs_valid_out),
        .ready_out(prbs_ready_out)
    );

    // FEC instantiation
    new_FEC fec_inst (
        .clk_50MHz(clk_50MHz),
        .clk_100MHz(clk_100MHz),
        .rst_n(rst_n),
        .data_in(prbs_data_out),
        .valid_in(prbs_valid_out),
        .ready_out(fec_ready_out),
        .valid_out(fec_valid_out),
        .serial_out(fec_data_out)
    );

    // Interleaver instantiation
    interleaver interleaver_inst (
        .clk(clk_100MHz),
        .reset(rst_n),
        .ready_in(modulator_ready_out),  // Connected to modulator's ready signal
        .data_valid(fec_valid_out),
        .input_data(fec_data_out),
        .ready_out(interleaver_ready_out),
        .output_data(interleaver_data_out),
        .valid_out(interleaver_valid_out)
    );

    // Modulator instantiation
    modulator modulator_inst (
        .clk(clk_100MHz),
        .rst(rst_n),
        .data_in(interleaver_data_out),
        .valid_in(interleaver_valid_out),
        .ready_out(modulator_ready_out),
        .valid_out(modulator_valid_out),
        .i_out(i_out),
        .q_out(q_out)
    );

    // PRBS verification
logic prbs_check_done;  // Add this flag

always_ff @(posedge clk_50MHz or negedge rst_n) begin
    if (!rst_n) begin
        prbs_counter <= '0;
        prbs_capture <= '0;
        verification_status[0] <= 1'b0;
        prbs_check_done <= 1'b0;
    end else if (prbs_valid_out) begin
        if (prbs_counter < 96) begin
            prbs_capture <= {prbs_capture[94:0], prbs_data_out};
            prbs_counter <= prbs_counter + 1'b1;
        end
    end
end

// Separate always block for comparison
always_ff @(posedge clk_50MHz or negedge rst_n) begin
    if (!rst_n) begin
        verification_status[0] <= 1'b0;
        prbs_check_done <= 1'b0;
    end else if (prbs_counter == 96 && !prbs_check_done) begin
        verification_status[0] <= (prbs_capture == EXPECTED_PRBS);
        prbs_check_done <= 1'b1;
    end
end

// FEC verification
logic fec_checked;

always_ff @(posedge clk_100MHz or negedge rst_n) begin
    if (!rst_n) begin
        fec_counter <= '0;
        fec_capture <= '0;
        verification_status[1] <= 1'b0;
        fec_checked <= 1'b0;
    end else begin
        // Only capture and verify if we haven't checked the first block yet
        if (fec_valid_out && !fec_checked) begin
            if (fec_counter < 192) begin
                fec_capture <= {fec_capture[190:0], fec_data_out};
                fec_counter <= fec_counter + 1'b1;
                
                // Verify first block when complete
                if (fec_counter == 191) begin
                    verification_status[1] <= ({fec_capture[190:0], fec_data_out} == EXPECTED_FEC);
                    fec_checked <= 1'b1;  // Lock in first block check
                end
            end
        end
    end
end

// Interleaver verification
logic interleaver_first_block_checked;
logic prev_interleaver_valid;

always_ff @(posedge clk_100MHz or negedge rst_n) begin
    if (!rst_n) begin
        interleaver_counter <= '0;
        interleaver_capture <= '0;
        verification_status[2] <= 1'b0;
        interleaver_first_block_checked <= 1'b0;
        prev_interleaver_valid <= 1'b0;
    end else begin
        prev_interleaver_valid <= interleaver_valid_out;
        
        // Detect rising edge of valid to reset capture
        if (interleaver_valid_out && !prev_interleaver_valid) begin
            interleaver_counter <= '0;
            interleaver_capture <= '0;
        end
        
        // Capture data while valid is high
        if (interleaver_valid_out && interleaver_counter < 192) begin
            interleaver_capture <= {interleaver_capture[190:0], interleaver_data_out};
            interleaver_counter <= interleaver_counter + 1'b1;
            
            // Check when we have a complete block
            if (interleaver_counter == 191 && !interleaver_first_block_checked) begin
                verification_status[2] <= ({interleaver_capture[190:0], interleaver_data_out} == EXPECTED_INTERLEAVER);
                interleaver_first_block_checked <= 1'b1;
            end
        end
    end
end

    // Modulator verification
    always_ff @(posedge clk_100MHz or negedge rst_n) begin
        if (!rst_n) begin
            modulator_counter <= '0;
            verification_status[3] <= 1'b0;
            for (int i = 0; i < 96; i++) begin
                i_samples[i] <= '0;
                q_samples[i] <= '0;
            end
        end else if (modulator_valid_out) begin
            if (modulator_counter < 96) begin
                // Store each new I/Q sample
                i_samples[modulator_counter] <= i_out;
                q_samples[modulator_counter] <= q_out;
                modulator_counter <= modulator_counter + 1'b1;
                
                // Verify when all samples are collected
                if (modulator_counter == 95) begin
                    verification_status[3] <= 1'b1;  // Start as true
                    for (int i = 0; i < 96; i++) begin
                        // Check if each I/Q pair matches valid constellation points
                        if ((i_samples[i] != POS_707 && i_samples[i] != NEG_707) ||
                            (q_samples[i] != POS_707 && q_samples[i] != NEG_707)) begin
                            verification_status[3] <= 1'b0;
                        end
                    end
                end
            end
        end
    end

    // Connect top-level signals
    assign ready_out = prbs_ready_out;
    assign valid_out = modulator_valid_out;
    assign serial_out = interleaver_data_out;
    assign verify_leds = verification_status;



endmodule