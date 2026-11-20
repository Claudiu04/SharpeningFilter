# FPGA Hardware Image Sharpening Accelerator (3x3 Kernel)

**[English](#english-version) | [Română](#versiunea-în-română)**

---

## <a name="english-version"></a> English

This repository contains a hardware IP (Intellectual Property) developed in SystemVerilog for applying a sharpening (Laplacian) filter on RGB or Grayscale images. The project is optimized for Xilinx Zynq SoCs and is ready for direct integration with Xilinx AXI DMA.

###  Key Features
* **Pipelined Architecture:** The data path is segmented into a 3-stage pipeline to break the critical path, enabling high-frequency operation (>=100 MHz) without *Timing Violations*.
* **Dynamic Edge Padding:** The module automatically replicates edge pixels to correctly calculate the 3x3 window on the image boundaries, completely eliminating boundary bypass artifacts.
* **Auto-Flush & Reset:** Internal logic recognizes the DMA's `TLAST` signal, forcing a complete flush of the data pipeline and automatic counter reset to process consecutive images without software intervention.
* **Flexible Resolution:** Supports images with a width of up to **3840 pixels** (4K UHD). Height is not hardware-limited.

###  System Architecture

The module utilizes two standard AMBA AXI interfaces:
1. **AXI4-Stream (S_AXIS & M_AXIS):** For high-speed video stream transfer (32-bit pixels). Connects to an AXI DMA (MM2S and S2MM).
2. **AXI4-Lite (S_AXI_LITE):** For configuring control registers by the processor (PS) prior to starting the video transfer.

###  Register Map (AXI4-Lite Memory Map)

| Offset | Register Name | Type | Description |
| :--- | :--- | :--- | :--- |
| `0x00` | `WIDTH` | R/W | Image width in pixels. |
| `0x04` | `HEIGHT` | R/W | Image height in pixels. |
| `0x08` | `CHANNELS` | R/W | Number of channels (1 for Grayscale, 3/4 for RGB/RGBA). |
| `0x0C` | `INTENSITY` | R/W | Intensity factor applied to the Laplacian filter (recommended: 1 - 300). |

---

## <a name="versiunea-în-română"></a> 🇷🇴 Română

Acest repository conține un IP (Intellectual Property) hardware dezvoltat în SystemVerilog pentru aplicarea unui filtru de sharpening (Laplacian) pe imagini RGB sau Grayscale. Proiectul este optimizat pentru SoC-uri Xilinx Zynq și este pregătit pentru integrare directă cu Xilinx AXI DMA.

###  Caracteristici Principale
* **Arhitectură Pipelined:** Calea de date este segmentată în 3 etaje de pipeline pentru a sparge drumul critic (critical path), permițând rularea la frecvențe înalte (>=100 MHz) fără *Timing Violations*.
* **Edge Padding Dinamic:** Modulul replică automat pixelii de pe margini pentru a calcula corect fereastra 3x3 pe extremele imaginii, eliminând complet "efectul de ramă" (boundary bypass artifacts).
* **Auto-Flush & Reset:** Logica internă recunoaște semnalul `TLAST` de la DMA, forțând golirea completă a conductei de date și resetarea automată a contoarelor pentru a procesa imagini consecutive fără intervenție software.
* **Rezoluție Flexibilă:** Suportă imagini cu lățimea de până la **3840 pixeli** (4K UHD). Înălțimea nu este limitată hardware.

###  Arhitectura Sistemului

Modulul utilizează două interfețe standard AMBA AXI:
1. **AXI4-Stream (S_AXIS & M_AXIS):** Pentru transferul de mare viteză al fluxului video (pixeli pe 32 de biți). Se conectează la un AXI DMA (MM2S și S2MM).
2. **AXI4-Lite (S_AXI_LITE):** Pentru configurarea registrelor de control de către procesor (PS) înainte de începerea transferului video.

###  Harta Registrelor (AXI4-Lite Memory Map)

| Offset | Nume Registru | Tip | Descriere |
| :--- | :--- | :--- | :--- |
| `0x00` | `WIDTH` | R/W | Lățimea imaginii în pixeli. |
| `0x04` | `HEIGHT` | R/W | Înălțimea imaginii în pixeli. |
| `0x08` | `CHANNELS` | R/W | Numărul de canale (1 pentru Grayscale, 3/4 pentru RGB/RGBA). |
| `0x0C` | `INTENSITY` | R/W | Factorul de intensitate aplicat filtrului Laplacian (recomandat: 1 - 300). |