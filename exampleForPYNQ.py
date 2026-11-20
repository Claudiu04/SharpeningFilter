from pynq import Overlay, allocate
import cv2
import numpy as np
import matplotlib.pyplot as plt
import time
import sys

sys.modules.pop('pynq.overlay', None)

overlay = Overlay("sharpen3x3.bit", download=True) 
dma = overlay.axi_dma_0
sharpening_ip = overlay.Sharpening3x3Kernel_0

img_bgr = cv2.imread("image.jpg") 
img_bgra = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2BGRA)

height, width, channels = img_bgra.shape
intensity = 100

in_buffer = allocate(shape=(height, width, 4), dtype=np.uint8)
out_buffer = allocate(shape=(height, width, 4), dtype=np.uint8)

in_buffer[:] = img_bgra

sharpening_ip.write(0x00, width)       # 0x00 -> slv_reg0 -> width
sharpening_ip.write(0x04, height)     # 0x04 -> slv_reg1 -> height
sharpening_ip.write(0x08, channels)       # 0x08 -> slv_reg2 -> channels
sharpening_ip.write(0x0C, intensity)  # 0x0C -> slv_reg3 -> intensity

start_time = time.perf_counter()

dma.recvchannel.transfer(out_buffer)
dma.sendchannel.transfer(in_buffer)
dma.sendchannel.wait()
dma.recvchannel.wait()

end_time = time.perf_counter()

timp_executie = end_time - start_time
print(f"Processing time (DMA + FPGA): {timp_executie:.5f} seconds")

img_rezultat_rgb = cv2.cvtColor(out_buffer, cv2.COLOR_BGRA2RGB)
img_original_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)

fig, axe = plt.subplots(1, 2, figsize=(16, 6)) 

axe[0].imshow(img_original_rgb)
axe[0].set_title("Original image")
axe[0].axis('off') 

axe[1].imshow(img_rezultat_rgb)
axe[1].set_title(f"FPGA Result - {timp_executie:.5f} seconds")
axe[1].axis('off')

plt.tight_layout() 
plt.show()

# Cleanup: Free the allocated buffers
in_buffer.freebuffer()
out_buffer.freebuffer()