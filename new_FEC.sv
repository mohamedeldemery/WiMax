module new_FEC (
    input  logic         clk_50MHz,      
    input  logic         clk_100MHz,
    input  logic         rst_n,          
    input  logic         data_in, 
    input  logic         valid_in,          
    output logic         ready_out,    
    output logic         valid_out,    
    output logic         serial_out    
);

    typedef enum logic [1:0] {
        IDLE,
        WRITE_BANK_A,
        READ_WRITE_A,
        READ_WRITE_B
    } state_t;
    
    state_t current_state, next_state;
    logic block_done;

    logic [5:0] shift_reg;
    logic [5:0] last_six_bits;
    logic [7:0] bank_a_counter;
    logic [7:0] bank_b_counter;
    logic [7:0] bank_read_a_counter;
    logic [7:0] bank_read_b_counter;
    logic [7:0] address_a, address_b;
    logic data_a;
    logic wren_a;
    logic rden_b;
    logic data_out_dprB;
    logic toggle_100MHz;
    logic [7:0] serial_counter;


    //assign valid_out = (serial_counter >= 6 && serial_counter <= 196);
    //assign valid_out = (current_state == READ_WRITE_A || current_state == READ_WRITE_B);
    assign valid_out = (serial_counter>=3 && serial_counter <= 194);
    assign wren_a = (((current_state == WRITE_BANK_A || current_state == READ_WRITE_A) && (bank_a_counter >= 0 && bank_a_counter <= 95))|| (current_state == READ_WRITE_B && (bank_b_counter >= 96 && bank_b_counter<192)));
    //assign rden_b = ((current_state == READ_WRITE_A && (bank_a_counter >= 1 && bank_a_counter <= 96))|| (current_state == READ_WRITE_B && (bank_b_counter >= 97 && bank_b_counter<=192)));
    assign ready_out = rst_n;
    //assign rden_b = ((current_state == READ_WRITE_A && (bank_read_b_counter >= 98 && bank_a_counter <= 193))|| (current_state == READ_WRITE_B && (bank_read_a_counter >= 1 && bank_read_a_counter<=96)));
    assign rden_b = (current_state == READ_WRITE_A || current_state == READ_WRITE_B);

    DPR dpr_inst (
        .address_a(address_a),
        .address_b(address_b),
        .clock_a(clk_50MHz),
        .clock_b(clk_50MHz),
        .data_a(data_a),
        .data_b(1'b0),
        .rden_a(1'b0),
        .rden_b(rden_b),
        .wren_a(wren_a),
        .wren_b(1'b0),
        .q_a(),
        .q_b(data_out_dprB)
    );

    always_ff @(posedge clk_50MHz or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // always_ff @(posedge clk_50MHz or negedge rst_n) begin
    //     if (!rst_n) begin
    //         rden_b <= '0;
    //     end
    //     else if (current_state == WRITE_BANK_A) begin
    //         rden_b <= '0;
    //     end
    //     else begin
    //         rden_b <= wren_a;
    //     end
    // end

    always_ff @(posedge clk_50MHz or negedge rst_n) begin
        if (!rst_n) begin
            bank_read_a_counter <= '0;
            bank_read_b_counter <= 8'd96;
        end else begin
            case (current_state)
                WRITE_BANK_A, READ_WRITE_A: begin
                   if (bank_read_b_counter < 192) begin
                        bank_read_b_counter <= bank_read_b_counter + 1'b1;
                    end 
                     else if (bank_read_b_counter >= 192) begin
                         bank_read_b_counter <= 8'd96;
                     end
                end
                READ_WRITE_B: begin
                     if (bank_read_a_counter < 8'd96) begin
                        bank_read_a_counter <= bank_read_a_counter + 1'b1;
                    end 
                     else if (bank_read_a_counter >= 96) begin
                         bank_read_a_counter <= '0;
                     end
                end
            endcase
        end
    end

    always_ff @(posedge clk_50MHz or negedge rst_n) begin
        if (!rst_n) begin
            bank_a_counter <= '0;
            bank_b_counter <= 8'd96;
        end else begin
            case (current_state)
                WRITE_BANK_A, READ_WRITE_A: begin
                    if (bank_a_counter < 8'd96) begin
                        bank_a_counter <= bank_a_counter + 1'b1;
                    end 
                     else if (bank_a_counter >= 96) begin
                         bank_a_counter <= '0;
                     end
                end
                READ_WRITE_B: begin
                    if (bank_b_counter < 192) begin
                        bank_b_counter <= bank_b_counter + 1'b1;
                    end 
                     else if (bank_b_counter >= 192) begin
                         bank_b_counter <= 8'd96;
                     end
                end
            endcase
        end
    end

    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (valid_in) next_state = WRITE_BANK_A;
            end
            WRITE_BANK_A: begin
                if (bank_a_counter >= 96 && valid_in) begin
                    next_state = READ_WRITE_B;
                end 
            end
            READ_WRITE_A: begin
                if (!valid_in && bank_a_counter >= 96) begin
                    next_state = IDLE;
                end else if (bank_a_counter >= 8'd96 && valid_in) begin
                    next_state = READ_WRITE_B;
                end
            end
            READ_WRITE_B: begin
                if (!valid_in && (bank_b_counter >= 192)) begin
                    next_state = IDLE;
                end else if (bank_b_counter >= 8'd192 && valid_in) begin
                    next_state = READ_WRITE_A;
                end
            end
        endcase
    end

    always_comb begin
        if (!rst_n) begin
            address_a <= 0;
            address_b <= 0;
        end
        else begin 
            case (current_state)
                WRITE_BANK_A: begin
                    address_a <= bank_a_counter;
                    address_b <= '0;
                end
                READ_WRITE_A: begin
                    address_a <= bank_a_counter;
                    address_b <= bank_read_b_counter;
                end
                READ_WRITE_B: begin
                    address_a <= bank_b_counter;
                    address_b <= bank_read_a_counter;
                end
            endcase
        end
    end

    // Memory write control
    always_ff @(posedge clk_50MHz or negedge rst_n) begin
        if (!rst_n) begin
            data_a <= '0;
        end 
        else begin
            case (current_state)
                WRITE_BANK_A, READ_WRITE_A,READ_WRITE_B: begin
                    data_a <= data_in;
                end
            endcase
        end
    end

    always_ff @(posedge clk_50MHz or negedge rst_n) begin
        if (!rst_n) begin
            last_six_bits <= '0;
        end else begin
            case (current_state)
                WRITE_BANK_A: begin
                    if (bank_a_counter >= 8'd90 && bank_a_counter <= 8'd95) begin
                        last_six_bits <= {data_a, last_six_bits[5:1]};
                    end
                end
                READ_WRITE_A: begin
                    if (bank_a_counter == 8'd88) begin
                        last_six_bits <= '0;
                    end else if (bank_a_counter >= 8'd90 && bank_a_counter <= 8'd95) begin
                        last_six_bits <= {data_a, last_six_bits[5:1]};
                    end
                end
                READ_WRITE_B: begin
                    if (bank_b_counter == 8'd180) begin
                        last_six_bits <= '0;
                    end else if (bank_b_counter >= 8'd186 && bank_b_counter <= 8'd191) begin
                        last_six_bits <= {data_a, last_six_bits[5:1]};
                    end
                end
                default: begin
                    last_six_bits <= last_six_bits;
                end
            endcase
        end
    end

    always_ff @(posedge clk_50MHz or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= '0;
        end else begin
            case (current_state)
                READ_WRITE_A: begin
                    if (bank_a_counter == 8'd0) begin
                        shift_reg <= last_six_bits;
                    end else if (bank_a_counter >= 8'd1 && bank_a_counter <= 8'd96) begin
                        shift_reg <= {data_out_dprB, shift_reg[5:1]};
                    end
                end
                READ_WRITE_B: begin
                    if (bank_b_counter == 8'd96) begin
                        shift_reg <= last_six_bits;
                    end else if (bank_b_counter >= 8'd96 && bank_b_counter <= 8'd192) begin
                        shift_reg <= {data_out_dprB, shift_reg[5:1]};
                    end
                end
                default: begin
                    shift_reg <= '0;
                end
            endcase
        end
    end

    always_ff @(posedge clk_100MHz or negedge rst_n) begin
    if (!rst_n) begin
        serial_counter <= '0;
    end
    else if(current_state == WRITE_BANK_A) begin
        serial_counter <= '0;
    end
    else if(serial_counter < 194 && (current_state == READ_WRITE_A || current_state == READ_WRITE_B)) begin  
        serial_counter <= serial_counter + 1;
    end
    else begin
        serial_counter <= 0;
    end
end
    
    // Toggle flip-flop at 100MHz
    always_ff @(posedge clk_100MHz or negedge rst_n) begin
        if (!rst_n) begin
            toggle_100MHz <= 1'b0;
        end else if (valid_out) begin
            toggle_100MHz <= ~toggle_100MHz;
        end
    end
    
    // Multiplexer for serial output
    always_ff @(posedge clk_100MHz or negedge rst_n) begin
        if (!rst_n) begin
            serial_out <= 1'b0;
        end else if (valid_out) begin
            if (!toggle_100MHz) begin
                //serial_out <= data_out_dprB ^ shift_reg[5] ^ shift_reg[4] ^ shift_reg[3] ^ shift_reg[0];
                serial_out <= data_out_dprB ^ shift_reg[4] ^ shift_reg[3] ^ shift_reg[1] ^ shift_reg[0];
            end
            else if (toggle_100MHz) begin
                //serial_out <= data_out_dprB ^ shift_reg[4] ^ shift_reg[3] ^ shift_reg[1] ^ shift_reg[0];
                serial_out <= data_out_dprB ^ shift_reg[5] ^ shift_reg[4] ^ shift_reg[3] ^ shift_reg[0];
            end
        end else begin
            serial_out <= 1'b0;
        end
    end

endmodule
