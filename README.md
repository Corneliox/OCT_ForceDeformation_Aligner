# OCT_ForceXDeformation_Aligner

**Optical Coherence Tomography (OCT) & Force Sensor Signal Alignment, Time-Warping, and Biomechanical Skin Stiffness Analysis**

---

## 📌 Project Overview
`OCT_ForceXDeformation_Aligner` is an advanced interactive MATLAB graphical user interface (GUI) and biomechanical analysis pipeline designed for **in-vivo skin indentation experiments**. It synchronizes high-speed optical deformation measurements from Optical Coherence Tomography (OCT) with external load-cell force sensor data.

The software performs non-linear **multi-cycle time-warping alignment**, calculates cyclic hysteresis loops, fits loading/recovery curves using power-law models ($F(w) = a \cdot w^b$), and evaluates tangent elastic moduli ($E_1, E_2, E_3$ at $1.5\%, 3.3\%, 5.0\%$ strain) based on the modified **Hayes Indentation Model**.

---

## ✨ Key Features
- **Dynamic Multi-Cycle Support (1 to 5 Waves)**: Configurable wave count selector dynamically adjusting signal segmentation, UI layout, and composite figures.
- **Interactive Annotation & Signal Pinning**:
  - Vertical pin snapping (`x_snap`, `y_snap`) directly onto curve values.
  - Interactive Undo via `Backspace` / `Delete` / `'b'` key.
  - Guided line visualizers during peak/trough selection.
- **Signal Filtering Options**:
  - `Raw (Default)`: Unfiltered baseline signal.
  - `Savitzky-Golay Filter`: High-order polynomial smoothing for noisy load-cell & optical signals.
- **Biomechanical Stiffness Engine**:
  - Power-law curve fitting ($F(w) = a_L \cdot w^{b_L}$ for loading, $a_R \cdot w^{b_R}$ for recovery).
  - Modified Hayes elastic modulus computation:
    $$E = \frac{1 - \nu^2}{2 \cdot a \cdot \kappa} \cdot \frac{dF}{dw} \cdot g$$
    where Poisson ratio $\nu = 0.45$, indenter radius $a = 2.5\text{ mm}$, aspect correction factor $\kappa = 3.085$, and gravity constant $g = 9.81\text{ m/s}^2$.
- **Comprehensive Data Export**:
  - **Excel Workbook**: Multi-sheet standardized export (`1_Deformation_Normal`, `2_Deformation_Inverted`, `3_Force_Vector`, `4_Merged_Plot`, `5_Hysteresis_Eval`, `6_Donut_Plot`, `7_Strain_Stiffening`).
  - **High-Resolution Figures**: Exportable in 150, 300 (Default), or 600 DPI across both **Light Mode** and **Dark Mode** color themes.

---

## 🗂️ Repository Structure
```
OCT_ForceXDeformation_Aligner/
├── OCT_ForceXDeformation_Aligner.m  # Main Interactive GUI Application (v2.0)
├── stiffnessOCT202606Original.m     # Baseline analysis script (v1.0 reference)
├── stiffnessOCT202606Changethis.m   # Working alias file
├── timeseries.csv                   # Sample input OCT thickness data
├── timeseries.png                   # Sample raw signal plot
├── README.md                        # Documentation & User Guide
├── LICENSE                          # MIT License
└── .gitignore                       # Git ignore configuration
```

---

## 🚀 Getting Started

### Prerequisites
- MATLAB R2020a or newer with **Image Processing Toolbox** and **Signal Processing Toolbox**.

### Running the Application
1. Clone the repository:
   ```bash
   git clone https://github.com/<YOUR_USERNAME>/OCT_ForceXDeformation_Aligner.git
   cd OCT_ForceXDeformation_Aligner
   ```
2. Open MATLAB and run:
   ```matlab
   OCT_ForceXDeformation_Aligner
   ```
3. Click **Browse Folder** to select the directory containing your OCT and Force CSV files.
4. Select the number of waves (1-5) and filter mode, then click **PROSES SEMUA SAMPEL**.

---

## 📜 Version History / Progression
1. **v1.0 (`stiffnessOCT202606Original.m`)**:
   - Initial baseline analysis script supporting fixed 3-wave manual point selection and basic Hayes indentation modulus computation.
2. **v2.0 (`OCT_ForceXDeformation_Aligner.m`)**:
   - Full refactor into a dynamic MATLAB App (`uifigure`).
   - Dynamic 1-5 wave cycle selection and automatic resizable grid layout.
   - Interactive Backspace undo and vertical pin-snapping to curve values.
   - Fail-safe duplicate sample point handling (`unique`) for robust interpolation.
   - Multi-sheet Excel workbook export and 300/600 DPI publication figure rendering.

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
