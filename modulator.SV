module modulator (
    input  logic        clk,
    input  logic        rst,
    input  logic        data_in,     // Serial input data
    input  logic        valid_in,    // Input data valid signal
    output logic        ready_out,   // Ready to accept data
    output logic        valid_out,   // Output data valid signal
    output logic signed [15:0] i_out, // In-phase component
    output logic signed [15:0] q_out  // Quadrature component
);
    
    localparam logic signed [15:0] POINT_707  = 16'sd11585;   // +0.707
    localparam logic signed [15:0] POINT_N707 = -16'sd11585;  // -0.707

    // Registers for storing bits and their flags
    logic bit_1;         // First received bit
    logic bit_2;         // Second received bit
    logic bit_1_valid;   // Flag indicating bit_1 has valid data
    logic bit_2_valid;   // Flag indicating bit_2 has valid data
    logic modulate;      // Flag indicating ready to modulate

    // Sequential logic for bit storage and processing
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            bit_1 <= 1'b0;
            bit_2 <= 1'b0;
            bit_1_valid <= 1'b0;
            bit_2_valid <= 1'b0;
            modulate <= 1'b0;
            ready_out <= 1'b1;    // Initially ready to accept data
            valid_out <= 1'b0;    // No valid output initially
            i_out <= '0;
            q_out <= '0;
        end else begin
            // Default values
            valid_out <= 1'b0;
            modulate <= 1'b0;

            // Input handling with handshaking
            if (valid_in && ready_out) begin
                if (!bit_1_valid) begin
                    bit_1 <= data_in;
                    bit_1_valid <= 1'b1;
                    bit_2_valid <= 1'b0;
                    ready_out <= 1'b1;     // Still ready for second bit
                end else if (!bit_2_valid) begin
                    bit_2 <= data_in;
                    bit_2_valid <= 1'b1;
                    bit_1_valid <= 1'b0;   // Prepare for next pair
                    modulate <= 1'b1;      // Signal to modulate
                    ready_out <= 1'b0;     // Not ready while modulating
                end
            end

            // Modulation phase
            if (modulate) begin
                case ({bit_1, bit_2})
                    2'b00: begin  // 45 degrees
                        i_out <= POINT_707;
                        q_out <= POINT_707;
                    end
                    2'b01: begin  // 135 degrees
                        i_out <= POINT_707;
                        q_out <= POINT_N707;
                    end
                    2'b10: begin  // -45 degrees
                        i_out <= POINT_N707;
                        q_out <= POINT_707;
                    end
                    2'b11: begin  // -135 degrees
                        i_out <= POINT_N707;
                        q_out <= POINT_N707;
                    end
                endcase
                valid_out <= 1'b1;    // Signal valid output
                ready_out <= 1'b1;    // Ready for next input
                bit_1_valid <= 1'b0;  // Clear valid flags
                bit_2_valid <= 1'b0;
            end
        end
    end

endmodule