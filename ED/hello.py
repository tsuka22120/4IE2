import richdem as rd

# DEMの読み込み
dem = rd.LoadGDAL("merge.tif")

# Sink fill
filled_dem = rd.FillDepressions(dem)

# Flow direction
flow_dir = rd.FlowDirectionD8(filled_dem)

# Flow accumulation
acc = rd.FlowAccumulation(flow_dir)

rd.SaveGDAL("flow_acc.tif", acc)
