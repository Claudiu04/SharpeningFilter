`timescale 1ns / 1ps


module sharpening #(

    parameter DATA_WIDTH = 32,
    parameter MAX_IMAGE_WIDTH = 3840

    )(

    input logic aclk, aresetn,

    input logic [DATA_WIDTH - 1 : 0] s_axis_tdata,
    input logic s_axis_tvalid,
    output logic s_axis_tready,
    input logic s_axis_tlast,
    
    output logic [DATA_WIDTH - 1 : 0] m_axis_tdata,
    output logic m_axis_tvalid,
    input logic m_axis_tready,
    output logic m_axis_tlast,
    
    input logic [31 : 0] height,
    input logic [31 : 0] width,
    input logic [31 : 0] channels,
    input logic [15 : 0] intensity

    );
    
    logic [7 : 0] R, G, B;
    logic [7 : 0] R_out, G_out, B_out;
    
    assign s_axis_tready = m_axis_tready;
    
    logic p_valid_reg;
    logic flush;
    
    
    always_ff @(posedge aclk) begin
    
        if(!aresetn) begin
        
            R <= 0; G <= 0; B <= 0;
            p_valid_reg <= 0;
            flush <= 0;
            
        end else begin
        
            if (s_axis_tvalid && s_axis_tready && s_axis_tlast) begin
                flush <= 1;
            end else if (m_axis_tvalid && m_axis_tready && m_axis_tlast) begin
                flush <= 0;
            end
        
            if ( s_axis_tready ) begin
            
                p_valid_reg <= s_axis_tvalid | flush;
            
                if( s_axis_tvalid ) begin
            
                    if(channels == 1 ) begin
                    
                        R <= s_axis_tdata[7:0];
                        G <= 8'd0;
                        B <= 8'd0;
                    
                    end else begin
                    
                        B <= s_axis_tdata[7:0];
                        G <= s_axis_tdata[15:8];
                        R <= s_axis_tdata[23:16];
                    
                    end
                     
                    
                    end                
                
            end else begin
            
                p_valid_reg <= 0;
            
            end
        
        end
    
    end
    
    logic buffer_tvalid;
    logic buffer_tlast;
    
    assign m_axis_tlast = buffer_tlast;
    assign m_axis_tvalid = buffer_tvalid;
    assign m_axis_tdata = (channels == 1) ?  {24'b00000000_00000000_00000000, R_out} : {8'b00000000, R_out, G_out, B_out};
    
    pixelBuffer #(
        
        .DATA_WIDTH(8),
        .MAX_IMAGE_WIDTH(3840)
    
        ) pixelBufferR (

        .aclk(aclk),
        .aresetn(aresetn),
        .p_valid(p_valid_reg),
        .img_width(width),
        .img_height(height),
        .intensity(intensity),
        .p_in(R),
        .p_out(R_out),
        .p_out_tvalid(buffer_tvalid),
        .p_out_tlast(buffer_tlast)

    );
    
    pixelBuffer #(
        
        .DATA_WIDTH(8),
        .MAX_IMAGE_WIDTH(3840)
    
        ) pixelBufferG (

        .aclk(aclk),
        .aresetn(aresetn),
        .p_valid(p_valid_reg),
        .img_width(width),
        .img_height(height),
        .intensity(intensity),
        .p_in(G),
        .p_out(G_out),
        .p_out_tvalid(),
        .p_out_tlast()

    );
    
    pixelBuffer #(
        
        .DATA_WIDTH(8),
        .MAX_IMAGE_WIDTH(3840)
    
        ) pixelBufferB (

        .aclk(aclk),
        .aresetn(aresetn),
        .p_valid(p_valid_reg),
        .img_width(width),
        .img_height(height),
        .intensity(intensity),
        .p_in(B),
        .p_out(B_out),
        .p_out_tvalid(),
        .p_out_tlast()

    );
    
endmodule
