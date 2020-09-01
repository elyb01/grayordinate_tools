% cifti_regress_nuisance(incifti,nreg,outcifti)
%
% version 1.1, 10/12/17
% Created by Ely
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
% nreg = input nuisance regressor(s) data (*.mat or *.txt), with each regressor as a separate column
% outcifti = filename of output cifti data (*.dtseries.nii)

%% declare function
function cifti_regress_nuisance(incifti,nreg,outcifti)

%% point to Connectome Workbench executable for your environment:
WBC='/Users/ely/Dropbox/SCIENCE/Software/workbench/bin_macosx64/wb_command';
%WBC='/hpc/packages/minerva-common/connectome/1.2.3/workbench/bin_rh_linux64/wb_command';

%% read CIFTI data
if exist(incifti,'file') == 2
	inc=ciftiopen(incifti,WBC);
	outc=inc;
else
	error('input cifti file not found');
end

%% read nuisance regressor data
if exist(nreg,'file') == 2
	[filepath,name,ext] = fileparts(nreg);
%	fprintf('filepath=%s\nname=%s\next=%s',filepath,name,ext);
	if ext=='.mat'
		NR=cell2mat(struct2cell(load(nreg)));
	elseif ext=='.txt'
		NR=load(nreg);
		[r,c]=size(NR);
		if c>r
			NR=NR'; % transpose if more columns than rows
		end
	else
		error('input nuisance regressor filetype not supported, must be .mat or .txt');
	end
else
	error('input nuisance regressor file not found');
end

%%  normalize nuisance regressors
normNR=functionnormalise(NR);

%%  remove nuisance regressors (hard regression)
outc.cdata = inc.cdata - (normNR * (pinv(normNR,1e-6) * inc.cdata'))';

%% save cleaned data to file
ciftisave(outc,outcifti,WBC);

