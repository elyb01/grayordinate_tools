%% MP_regress_ICAFIX_noise(subdir,fixlist,aggressive,hp)
%
% version 1.0, 31 Aug 2020
% Created by Ely (benjamin dot ely at einsteinmed dot edu)
% Removes sICA-FIX noise components from pseudo-NIFTI format movement parameter data and saves the residuals
% outputs can  then be converted to a .txt MP file and regresssed out of target NIFTI/CIFTI files withtout re-introducing variance from noise components
% Generally only needed for after-the-fact MP regression of multi-run ICA-FIX denoised data without simultaneous MP regression
% Code taken pretty directly from FIX v1.06.15 fix_3_clean.m script, which creates these denoised MP .txt files automatically
% see: https://git.fmrib.ox.ac.uk/fsl/fix/-/blob/master/fix_3_clean.m
%
% subdir = /full/path/to/subject/directory
% fixlist = list of noise ICs (typically HandNoise.txt)
% aggressive = 1 to remove all noise-related variance (typically 0, should match denoising of target NIFTI/CIFTI)
% hp = ICA-FIX high-pass filter value (typically 2000)

%% declare function
function MP_regress_ICAFIX_noise(subdir,fixlist,aggressive,hp)

if ischar(aggressive)
    aggressive = str2num(aggressive);
end
if ischar(hp)
    hp = str2num(hp);
end

%%% report parameters
fprintf('subject = %s\n',subdir);
fprintf('aggressive = %d\n',aggressive);
fprintf('hp = %f\n',hp);

%%% move to subject folder
cd(sprintf('%s/MNINonLinear/Results/fMRI_merged/fMRI_merged_hp2000.ica',subdir));

%%% read set of bad components
DDremove=load(fixlist);

%%% find TR of data
[grot,TR]=call_fsl('fslval filtered_func_data pixdim4'); 
TR=str2num(TR);
fprintf('TR = %f\n',TR);

%%% read ICA component timeseries
ICA=functionnormalise(load(sprintf('filtered_func_data.ica/melodic_mix')));

%%%% compute movement regressors with noise components removed
confounds = functionmotionconfounds(TR,hp);
if aggressive == 1
    % aggressively regress out noise ICA components from movement regressors
    betaconfounds = pinv(ICA(:,DDremove),1e-6) * confounds;                              % beta for confounds (bad only)
    confounds = confounds - (ICA(:,DDremove) * betaconfounds);    % cleanup
else
    % non-aggressively regress out noise ICA components from movement regressors
    betaconfounds = pinv(ICA,1e-6) * confounds;                              % beta for confounds (good *and* bad)
    confounds = confounds - (ICA(:,DDremove) * betaconfounds(DDremove,:));    % cleanup
end
save_avw(reshape(confounds',size(confounds,2),1,1,size(confounds,1)),'mc/prefiltered_func_data_mcf_conf_hp_clean','f',[1 1 1 TR]);
% 
% 
% 
% %% point to Connectome Workbench executable for your environment:
% %WBC='/Users/ely/Dropbox/SCIENCE/Software/workbench/bin_macosx64/wb_command';
% %WBC='/hpc/packages/minerva-common/connectome/1.2.3/workbench/bin_rh_linux64/wb_command';
% 
% %% read CIFTI data
% if exist(incifti,'file') == 2
% 	inc=ciftiopen(incifti,WBC);
% 	outc=inc;
% else
% 	error('input cifti file not found');
% end
% 
% 
% %%%%  read ICA component timeseries
% ICA=functionnormalise(load(sprintf('filtered_func_data.ica/melodic_mix')));
% 
% 
% %% read nuisance regressor data
% if exist(nreg,'file') == 2
% 	[filepath,name,ext] = fileparts(nreg);
% %	fprintf('filepath=%s\nname=%s\next=%s',filepath,name,ext);
% 	if ext=='.mat'
% 		NR=cell2mat(struct2cell(load(nreg)));
% 	elseif ext=='.txt'
% 		NR=load(nreg);
% 		[r,c]=size(NR);
% 		if c>r
% 			NR=NR'; % transpose if more columns than rows
% 		end
% 	else
% 		error('input nuisance regressor filetype not supported, must be .mat or .txt');
% 	end
% else
% 	error('input nuisance regressor file not found');
% end
% 
% %%  normalize nuisance regressors
% normNR=functionnormalise(NR);
% 
% %%  remove nuisance regressors (hard regression)
% outc.cdata = inc.cdata - (normNR * (pinv(normNR,1e-6) * inc.cdata'))';
% 
% %% save cleaned data to file
% ciftisave(outc,outcifti,WBC);
% 
