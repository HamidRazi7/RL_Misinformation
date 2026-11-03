script_dir = fileparts(mfilename('fullpath'));
rl_root = fileparts(fileparts(script_dir));
codes_root = fileparts(rl_root);
output_dir = fullfile(rl_root, 'Data', 'Processed', 'Results');
vba_dir = fullfile(rl_root, 'VBA-toolbox');

addpath(genpath(vba_dir));
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

full_results = table();
pairwise_results = table();

for study = 1:2
    input_path = fullfile(output_dir, sprintf('ten_model_LOOCV_study%d.csv', study));
    loocv = readtable(input_path, 'VariableNamingRule', 'preserve');
    model_names = string(loocv.Properties.VariableNames)';

    options = struct();
    options.MaxIter = 100;
    options.verbose = 0;

    log_model_evidence = -table2array(loocv)';
    [~, out] = VBA_groupBMC(log_model_evidence, options);

    study_column = repmat("Study " + string(study), length(model_names), 1);
    bor_column = repmat(out.bor, length(model_names), 1);
    se_column = sqrt(out.Vf(:));
    study_results = table( ...
        study_column, model_names, out.Ef(:), se_column, out.ep(:), out.pxp(:), bor_column, ...
        'VariableNames', { ...
            'Study', 'Model', 'EstimatedModelFrequency', 'ModelFrequencySE', ...
            'ExceedanceProbability', 'ProtectedExceedanceProbability', ...
            'BayesianOmnibusRisk'} ...
    );
    full_results = [full_results; study_results];

    pair_sets = {[4 6], [6 7], [6 8], [6 9], [6 10]};
    pair_labels = ["M6 (M4Rho) vs M4", "M6 (M4Rho) vs M1Rho", ...
                   "M6 (M4Rho) vs M2Rho", "M6 (M4Rho) vs M3Rho", ...
                   "M6 (M4Rho) vs M5Rho"];
    for pair_index = 1:length(pair_sets)
        selected = pair_sets{pair_index};
        pair_evidence = -table2array(loocv(:, selected))';
        [~, pair_out] = VBA_groupBMC(pair_evidence, options);

        pair_models = model_names(selected);
        pair_study = repmat("Study " + string(study), length(selected), 1);
        pair_comparison = repmat(pair_labels(pair_index), length(selected), 1);
        pair_bor = repmat(pair_out.bor, length(selected), 1);
        pair_se = sqrt(pair_out.Vf(:));
        pair_result = table( ...
            pair_study, pair_comparison, pair_models, pair_out.Ef(:), pair_se, ...
            pair_out.ep(:), pair_out.pxp(:), pair_bor, ...
            'VariableNames', { ...
                'Study', 'Comparison', 'Model', 'EstimatedModelFrequency', 'ModelFrequencySE', ...
                'ExceedanceProbability', 'ProtectedExceedanceProbability', ...
                'BayesianOmnibusRisk'} ...
        );
        pairwise_results = [pairwise_results; pair_result];
    end
end

writetable(full_results, fullfile(output_dir, 'ten_model_random_effects_BMS.csv'));
writetable(pairwise_results, fullfile(output_dir, 'ten_model_pairwise_random_effects_BMS.csv'));

disp('Full ten-model comparison (M6 = M4Rho):');
disp(full_results);
disp('Head-to-head comparisons:');
disp(pairwise_results);
