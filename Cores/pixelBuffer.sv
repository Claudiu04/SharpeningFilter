`timescale 1ns / 1ps

module pixelBuffer #( 
        parameter DATA_WIDTH = 8,
        parameter MAX_IMAGE_WIDTH = 3840
        )(

        input logic aclk,
        input logic aresetn,
        input logic p_valid,
        input logic [31:0] img_height,
        input logic [31:0] img_width,
        input logic [15:0] intensity,
        
        input logic [DATA_WIDTH - 1:0] p_in,
        output logic [DATA_WIDTH - 1:0] p_out,
        output logic p_out_tvalid,
        output logic p_out_tlast        

    );
    
    logic [DATA_WIDTH - 1:0] lineBuffer1 [0 : MAX_IMAGE_WIDTH - 1];
    logic [DATA_WIDTH - 1:0] lineBuffer2 [0 : MAX_IMAGE_WIDTH - 1];
    
    logic [DATA_WIDTH - 1 : 0] p00, p01, p02;
    logic [DATA_WIDTH - 1 : 0] p10, p11, p12;
    logic [DATA_WIDTH - 1 : 0] p20, p21, p22;
    logic [DATA_WIDTH - 1 : 0] pb_in;
    
    logic [15:0] col, row;
    logic [DATA_WIDTH - 1 : 0] pb1, pb2;
    
    always_ff @(posedge aclk) begin
        if ( !aresetn ) begin
            p00 <= 0; p01 <= 0; p02 <= 0;
            p10 <= 0; p11 <= 0; p12 <= 0;
            p20 <= 0; p21 <= 0; p22 <= 0;
            pb_in <= 0;
        end else begin
            if ( p_valid ) begin
            
                pb_in <= p_in;
            
                p00 <= p01;
                p01 <= p02;
                p02 <= pb2;
                
                p10 <= p11;
                p11 <= p12;
                p12 <= pb1;
                
                p20 <= p21;
                p21 <= p22;
                p22 <= pb_in;
            end
        end
    end
    
    always_ff @(posedge aclk) begin
        if( !aresetn ) begin
            pb1 <= 0;
            pb2 <= 0;
            col <= 0;
            row <= 0;
        end else begin
            if (p_out_tlast) begin
                col <= 0;
                row <= 0;
            end else if( p_valid ) begin
                pb1 <= lineBuffer1[col];
                pb2 <= lineBuffer2[col];
                
                lineBuffer2[col] <= lineBuffer1[col];
                lineBuffer1[col] <= p_in;
                
                if ( col == img_width - 1 ) begin
                    if( row == img_height - 1) begin
                        row <= 0;
                    end else begin
                        row <= row + 1;
                    end
                    col <= 0;
                end else begin
                    col <= col + 1;
                end
            end
        end
    end
    
    logic [15:0] out_col, out_row;
    logic output_active;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            out_col <= 0;
            out_row <= 0;
            output_active <= 0;
        end else begin
            if (p_valid) begin
                if (row == 1 && col == 2) begin
                    output_active <= 1;
                end
                if (output_active) begin
                    if (out_col == img_width - 1) begin 
                        out_col <= 0;
                        if (out_row == img_height - 1) begin 
                            out_row <= 0;
                            output_active <= 0; 
                        end else begin
                            out_row <= out_row + 1;
                        end
                    end else begin
                        out_col <= out_col + 1;
                    end
                end
            end
        end
    end
    
    logic signed [15:0] p_temp;
    logic signed [11:0] sp11 , sp01, sp12, sp10, sp21;
    assign sp01 = {4'b0, p01};
    assign sp10 = {4'b0, p10};
    assign sp12 = {4'b0, p12};
    assign sp21 = {4'b0, p21};
    assign sp11 = {4'b0, p11};

    logic signed [11:0] pixel_top, pixel_bottom, pixel_left, pixel_right;
    
    assign pixel_top    = (out_row == 0) ? sp11 : sp01;
    assign pixel_bottom = (out_row == img_height - 1) ? sp11 : sp21;
    assign pixel_left   = (out_col == 0) ? sp11 : sp10;
    assign pixel_right  = (out_col == img_width - 1) ? sp11 : sp12;
        
    logic signed [12:0] laplacian;
    assign laplacian = ( sp11 << 2 ) - pixel_top - pixel_bottom - pixel_left - pixel_right;
    
    
    logic [15:0] out_col_late, out_row_late;
    logic output_active_late;
    logic signed [12:0] laplacian_late;
    logic signed [11:0] sp11_late;
    logic signed p_valid_late;
    
    always_ff @(posedge aclk) begin
    
        if (!aresetn) begin
        
            out_col_late <= 0;
            out_row_late <= 0;
            laplacian_late <= 0;
            sp11_late <= 0;
            output_active_late <= 0;
            p_valid_late <= 0;
        
        end else begin
        
            out_col_late <= out_col;
            out_row_late <= out_row;
            laplacian_late <= laplacian;
            sp11_late <= sp11;
            output_active_late <= output_active;
            p_valid_late <= p_valid;
        
        end
    
    
    end

    logic signed [28:0] scaled_laplacian_pipe;
    logic signed [11:0] sp11_pipe;
    logic [15:0] out_col_pipe, out_row_pipe;
    logic output_active_pipe;
    logic p_valid_pipe;
    
    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            scaled_laplacian_pipe <= 0;
            sp11_pipe <= 0;
            out_col_pipe <= 0;
            out_row_pipe <= 0;
            output_active_pipe <= 0;
            p_valid_pipe <= 0;
        end else begin
            scaled_laplacian_pipe <= laplacian_late * $signed({1'b0 , intensity});
            
            sp11_pipe <= sp11_late;
            
            out_col_pipe <= out_col_late;
            out_row_pipe <= out_row_late;
            output_active_pipe <= output_active_late;
            p_valid_pipe <= p_valid_late;
        end
    end
    
    assign p_temp = sp11_pipe + (scaled_laplacian_pipe >>> 8);
    
    always_ff @(posedge aclk) begin
        if( !aresetn ) begin
            p_out <= 0;
        end else begin
            
            if ( p_temp < 0 ) begin
                p_out <= 0;
            end else if( p_temp > 255 ) begin
                p_out <= 255;
            end else begin
                p_out <= p_temp[7:0];
            end
            
        end
    end
    

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            p_out_tvalid <= 0;
            p_out_tlast <= 0;
        end else begin
        
            p_out_tvalid <= output_active_pipe & p_valid_pipe; 
            
            if (output_active_pipe && p_valid_pipe && out_col_pipe == img_width - 1 && out_row_pipe == img_height - 1) begin
                p_out_tlast <= 1'b1;
            end else begin
                p_out_tlast <= 1'b0;
            end
        end
    end
    
endmodule