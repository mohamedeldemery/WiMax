module interleaver(
    input logic clk,
    input logic reset,
    input logic ready_in,
    input logic data_valid,
    input logic input_data,
    output logic ready_out,
    output logic output_data,
    output logic valid_out
);

    typedef enum {
        IDLE,
        WRITE_BANK_A,    // Initial write to first bank
        READ_WRITE_A,    // Writing to bank A while reading from bank B
        READ_WRITE_B     // Writing to bank B while reading from bank A
    } state_t;

    state_t current_state, next_state;

    // Counters for write operations
    logic [8:0] write_counter;
    // Counter for read operations
    logic [8:0] read_counter;
    
    // Memory interface signals
    logic [8:0] address_a;  
    logic [8:0] address_b;
    logic data_a;    
    logic rden_b, wren_a;
    logic ram_out_b;

    // Control signals
    assign wren_a = ((data_valid || write_counter >= 0) && write_counter <= 191);  // Always write when not in IDLE
    assign rden_b = (current_state == READ_WRITE_A || current_state == READ_WRITE_B);
    assign ready_out = (current_state != IDLE);
    assign valid_out = rden_b;
    assign output_data = ram_out_b;

    // State register
    always_ff @(posedge clk or negedge reset) begin
        if (!reset)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // Next state logic - simplified, not dependent on data_valid
    always_comb begin
        next_state = current_state;

        case (current_state)
            IDLE: begin
                next_state = WRITE_BANK_A;
            end

            WRITE_BANK_A: begin
                if (write_counter >= 9'd191) begin
                    next_state = READ_WRITE_B;
                end
            end

            READ_WRITE_B: begin
                if (write_counter >= 9'd383) begin
                    next_state = READ_WRITE_A;
                end
            end

            READ_WRITE_A: begin
                if (write_counter >= 9'd191) begin
                    next_state = READ_WRITE_B;
                end
            end
        endcase
    end

    // Write counter logic
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            write_counter <= '0;
        end
        else begin
            case (current_state)
                IDLE: begin
                    write_counter <= '0;
                end
                
                default: begin
                    if (data_valid) begin
                        if (current_state == READ_WRITE_B && write_counter >= 9'd383) begin
                            write_counter <= '0;
                        end
                        else if (current_state == READ_WRITE_A && write_counter >= 9'd191) begin
                            write_counter <= 9'd192;
                        end
                        else begin
                            write_counter <= write_counter + 1'b1;
                        end
                    end
                end
            endcase
        end
    end

    // Read counter logic
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            read_counter <= 0;  // Start reading from bank B
        end
        else if (data_valid) begin
            if (current_state == READ_WRITE_B) begin
                
                    read_counter <= read_counter + 1'b1;
                
            end
            else if (current_state == READ_WRITE_A) begin
                    read_counter <= read_counter + 1'b1;
                    if (read_counter== 9'd383)
                    read_counter<=0;
        end
    end
    end 

    // Address generation
    always_comb begin
        // Write address (Port A)
        if (write_counter < 9'd384) begin
            address_a = 9'd12 * (write_counter % 9'd16) + (write_counter / 9'd16);
        end
        else begin
            address_a = '0;
        end

        // Read address (Port B)
        address_b = read_counter;
    end

    // // Input data register
    // always_ff @(posedge clk or negedge reset) begin
    //     if (!reset)
    //         data_a <= '0;
    //     else if (data_valid)
    //         data_a <= input_data;
    // end

    // RAM instantiation
    RAM4P RAM_4P (
        .address_a(address_a),
        .address_b(address_b),
        .clock_a(clk),
        .clock_b(clk),
        .data_a(input_data),
        .data_b(1'b0),
        .rden_a(1'b0),
        .rden_b(rden_b),
        .wren_a(wren_a),
        .wren_b(1'b0),
        .q_a(),
        .q_b(ram_out_b)
    );

endmodule