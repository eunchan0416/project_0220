`timescale 1ns / 1ps


module data_mem (
    input               clk,
    input               rst,
    input               dwe,
    input        [31:0] dwdata,
    input        [ 2:0] c2dm_funct3,
    input        [31:0] daddr,
    output logic [31:0] drdata

);

    logic [31:0] dmem      [0:255];
    logic [ 7:0] byte_load;
    logic [15:0] half_load;
    logic [31:0] word_load;

    //word address
    always_ff @(posedge clk) begin
        if (dwe) begin
            case (c2dm_funct3)

                3'b000: begin
                    case (daddr[1:0])
                        2'b00: begin
                            dmem[daddr[31:2]][7:0] <= dwdata[7:0];
                        end
                        2'b01: begin
                            dmem[daddr[31:2]][15:8] <= dwdata[7:0];

                        end
                        2'b10: begin
                            dmem[daddr[31:2]][23:16] <= dwdata[7:0];
                        end
                        default: begin
                            dmem[daddr[31:2]][31:24] <= dwdata[7:0];
                        end
                    endcase
                end

                3'b001: begin
                    if (daddr[1:0] == 0) begin
                        dmem[daddr[31:2]][15:0] <= dwdata[15:0];
                    end else begin
                        dmem[daddr[31:2]][31:16] <= dwdata[15:0];
                    end

                end

                3'b010: begin
                    dmem[daddr[31:2]] <= dwdata;
                end
                default: dmem[daddr[31:2]] <= dmem[daddr[31:2]];
            endcase
        end



    end

    always_comb begin

        word_load = dmem[daddr[31:2]];

        case (daddr[1:0])

            2'b00:   byte_load = word_load[7:0];
            2'b01:   byte_load = word_load[15:8];
            2'b10:   byte_load = word_load[23:16];
            default: byte_load = word_load[31:24];

        endcase

        if (daddr[1]) half_load = word_load[31:16];
        else half_load = word_load[15:0];




        if (!dwe) begin
            case (c2dm_funct3)
                3'b000: begin
                    drdata = {{24{byte_load[7]}}, byte_load};
                end
                3'b001: begin
                    drdata = {{16{half_load[15]}}, half_load};
                end
                3'b010: begin
                    drdata = word_load;
                end
                3'b100: begin
                    drdata = {{24{1'b0}}, byte_load};
                end
                3'b101: begin
                    drdata = {{16{1'b0}}, half_load};
                end
                default: drdata = word_load;
            endcase

        end else drdata = dmem[daddr[31:2]];

    end




endmodule
