# Software Repository - Spatial Audio Scene Characterization (SASC): Automatic Lo-calization of Front, Back, Up, and Down-Positioned Music Ensembles in Binaural Recordings
This repository consists of scripts and data useful to replicate the experiments described in the paper "Spatial Audio Scene Characterization (SASC): Automatic Localization of Front, Back, Up, and Down-Positioned Music En-sembles in Binaural Recordings".

## Structure
The repository is organized as follows:
- [models](models) - the deep learning models that were trained in the study
- [scripts](scripts) - scripts used in the development of the deep learning algorithm: finding hyperparameters, model traning, evaluation, visualization, and statistical calculations
- [data](data) - partial results and detailed description of the data used in the study 

## Dependencies
Software dependencies:
- [MATLAB](https://www.mathworks.com/products/matlab.html) - a development environment used to implement models
- [VOICEBOX](http://www.ee.ic.ac.uk/hp/staff/dmb/voicebox/voicebox.html) - a toolbox used to implement the binaural convolver
- [SOFA](https://github.com/sofacoustics/API_MO) - a file format for reading, saving, and describing spatially oriented data of acoustic systems.

## Authors
Sławomir K. Zieliński <sup>1</sup>, Paweł Antoniuk <sup>1</sup>, and Hyunkook Lee <sup>2</sup>

<sup>1</sup> Faculty of Computer Science, Białystok University of Technology, 15-351 Białystok, Poland; s.zielinski@pb.edu.pl (S.K.Z.); p.antoniuk6@student.pb.edu.pl (P.A.)

<sup>2</sup> Applied Psychoacoustics Laboratory (APL), University of Huddersfield, Huddersfield HD1 3DH, UK; H.Lee@hud.ac.uk (H.L.); D.S.Johnson2@hud.ac.uk (D.J.)

## License
The content of this repository is licensed under the terms of the GNU General Public License v3.0 license. Please see the [LICENSE](LICENSE) file for more details.
