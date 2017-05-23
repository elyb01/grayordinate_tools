% cifti_regress_nuisance(incifti,nreg,outcifti)
%
% version 1.0, 5/17/17
% Created by Ely (benjamin dot ely at mssm dot edu)
% Based on fix_3_clean.m from ICA-FIX; also owes much to the NITRC conn toolbox
%
% Removes nuisance regressors from CIFTI data and saves the residuals as a new CIFTI file
% Designed to work with ICA-FIX denoised CIFTI data.
% Any filtering/detrending applied to the input CIFTI data should also be applied to the nuisance regressors before running.
% Bandpass filtering should be performed after nuisance regressors are removed (see Hallquist MN et al, Neuroimage, 2013)
%
% Requires the HCP Pipeline gifti/cifti library (see https://wiki.humanconnectome.org/display/PublicData/HCP+Users+FAQ)
%
% incifti = filename of input cifti data (*.dtseries.nii)
% nreg = input nuisance regressor(s) data (*.mat), with each regressor as a separate column % will add .txt/.csv support later
% outcifti = filename of output cifti data (*.dtseries.nii)

%% declare function
function cifti_regress_nuisance(incifti,nreg,outcifti)

%% adjust these settings for your environment:
%WBC='/Users/ely/Dropbox/SCIENCE/Software/workbench/bin_macosx64/wb_command';
WBC='/hpc/packages/minerva-common/connectome/1.2.3/workbench/bin_rh_linux64/wb_command';

%% read CIFTI data
if exist(incifti,'file') == 2
	inc=ciftiopen(incifti,WBC);
	outc=inc;
else
	error('input cifti file not found');
end

%% read nuisance regressor data
if exist(nreg,'file') == 2
	NR=cell2mat(struct2cell(load(nreg)));
else
	error('input nuisance regressor file not found');
end

%%  normalize nuisance regressors
normNR=functionnormalise(NR);

%%  remove nuisance regressors (hard regression)
outc.cdata = inc.cdata - (normNR * (pinv(normNR,1e-6) * inc.cdata'))';

%% save cleaned data to file
ciftisave(outc,outcifti,WBC);

%% BONEYARD
% Soft regression - code below gives same output as hard regression
%function cifti_regress_nuisance(incifti,nreg,aggro,outcifti)
%if strcmp(aggro,'hard')
%	sprintf('hard regression')
%	outc.cdata = inc.cdata - (normNR * (pinv(normNR,1e-6) * inc.cdata'))';
%elseif strcmp(aggro,'soft')
%	sprintf('soft regression')
%	betaNR = pinv(normNR,1e-6) * inc.cdata';	% beta for nuisance regressors
%	outc.cdata = inc.cdata - (normNR * betaNR)';    % cleanup
%end

