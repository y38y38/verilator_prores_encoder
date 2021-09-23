//'define SET_DATA32(x)   ((x & 32'h000000ff) << 24 | (x & 32'h0000ff00) << 8 | (x & 32'h00ff0000) >> 8 | (x & 32'hff000000) >> 24 )
`define SET_DATA32(x)   ((x & 64'h000000ff) << 24 | (x & 64'h0000ff00) << 8 | (x & 64'h00ff0000) >> 8 | (x & 64'hff000000) >> 24 )
`define SET_DATA16(x)   ((x & 64'h00ff) << 8 | (x & 64'hff00) >> 8 )


