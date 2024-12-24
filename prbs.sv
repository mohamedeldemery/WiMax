module prbs_randomizer (
    input  logic        clk,         // Clock
    input  logic        rst_n,       // Active-low reset
    input  logic        ready_in,    // FEC is ready for our data
    input  logic        data_in,     // Input data (1 bit)
    input  logic        valid_in,    // Input data valid
    input  logic [14:0] seed,        // PRBS seed (15 bits)
    output logic        data_out,    // Randomized output data (1 bit)
    output logic        valid_out,   // Valid output data
    output logic        ready_out    // We're ready for input
);

    logic [14:0] LFSR;
    
    logic [6:0] bit_counter;

    // We're first in chain, so always ready
    assign ready_out = 1'b1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 0;
        end else if (valid_in && ready_in) begin
            if (bit_counter == 95) begin
                bit_counter <= 0;
            end else begin
                bit_counter <= bit_counter + 1;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            LFSR <= seed;
        end else begin
            if (valid_in) begin
                if (bit_counter == 95) begin
                    LFSR <= seed;
                end else begin
                    LFSR <= {LFSR[0] ^ LFSR[1], LFSR[14:1]};
                end
            end 
        end
    end
assign data_out = data_in ^ (LFSR[0] ^ LFSR[1]);
assign valid_out = valid_in;
endmodule