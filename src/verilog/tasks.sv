task initialize_signals();
   begin
      #OFFSET i_async_rst=1'b1;
              i_clk      =1'b0;
      #OFFSET i_mode     = '0;
      #OFFSET i_bypass   = '0;
      #OFFSET i_stop_code= '0;
      #OFFSET i_vld      = '0;
      #OFFSET i_data     = '0;
   end
endtask

task reset_signals();
   begin
      repeat (10) @(posedge i_clk);
      initialize_signals();
   end
endtask

task simple();
   begin
      reset_signals();
        
      @(posedge i_clk);
      #OFFSET i_mode       =  2'b10;
      #OFFSET i_bypass     =  3'b010;
      #OFFSET i_stop_code  = 49'd100;
      #ASYNC_RST_OFFSET i_async_rst  =  1'b0;
      
      repeat (10) @(posedge i_clk);
      @(posedge i_clk);
      #OFFSET i_vld        =  1'b1;
      //#OFFSET i_data       = {1'b0,16'h2000,16'h2000,16'h2000};
      #OFFSET i_data       = {1'b1,16'hA3D6,16'h3C69,16'h5B48};
      @(posedge i_clk);
      #OFFSET i_vld        =  1'b0;
      repeat (20) @(posedge i_clk);
      @(posedge i_clk);
      #OFFSET i_vld        =  1'b1;
      #OFFSET i_data       = 49'd100;
      @(posedge i_clk);
      #OFFSET i_vld        =  1'b0;
      
      reset_signals();
    end
endtask


