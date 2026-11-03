script_dir = fileparts(mfilename('fullpath'));
rl_root = fileparts(fileparts(script_dir));
codes_root = fileparts(rl_root);
vba_dir = fullfile(rl_root, 'VBA-toolbox');
addpath(genpath(vba_dir));

model_names = ["M1", "M2", "M3", "M4", "M5", "M6"];
K = numel(model_names);
n_iter = 50;
n_subjects = [100, 100];
results_prefix = 'Results_N100_50iter';
outtag = 'N100_50iter';
studies = 1;

set(0, 'DefaultFigureVisible', 'off');

options = struct();
options.MaxIter = 100;
options.verbose = 0;
options.DisplayWin = 0;

for study = studies
    res_dir = fullfile(script_dir, sprintf('%s_Study%d', results_prefix, study));
    winners = table();
    counts = zeros(K, K);
    frequencies = table();

    for iter = 1:n_iter
        for ti = 1:K
            true_model = model_names(ti);
            files = strings(1, K);
            have_all = true;
            S = NaN(n_subjects(study), K);
            for fi = 1:K
                files(fi) = fullfile(res_dir, sprintf('scores_s%d_i%d_%s_%s.csv', ...
                    study, iter, true_model, model_names(fi)));
                if ~isfile(files(fi))
                    have_all = false;
                    break;
                end
                tbl = readtable(files(fi));
                if height(tbl) ~= n_subjects(study)
                    have_all = false;
                    break;
                end
                S(:, fi) = tbl.Values;
            end
            if ~have_all
                continue;
            end

            [~, out] = VBA_groupBMC(-S', options);
            [~, xp_winner] = max(out.ep(:));

            [~, loocv_winner] = min(sum(S, 1));

            row = table(string(study), string(iter), string(true_model), ...
                string(model_names(xp_winner)), out.ep(xp_winner), out.pxp(xp_winner), ...
                string(model_names(loocv_winner)), out.bor, ...
                'VariableNames', {'Study', 'Iteration', 'TrueModel', 'XPWinner', ...
                                  'WinnerExceedanceProb', 'WinnerProtectedXP', ...
                                  'LOOCVWinner', 'BayesianOmnibusRisk'});
            winners = [winners; row];
            counts(ti, xp_winner) = counts(ti, xp_winner) + 1;

            freq_row = table(repmat(string(study), K, 1), repmat(string(iter), K, 1), ...
                repmat(string(true_model), K, 1), model_names(:), out.Ef(:), out.ep(:), out.pxp(:), ...
                'VariableNames', {'Study', 'Iteration', 'TrueModel', 'FittedModel', ...
                                  'Frequency', 'ExceedanceProb', 'ProtectedXP'});
            frequencies = [frequencies; freq_row];
        end
    end

    if isempty(winners)
        fprintf('Study %d: no complete units yet.\n', study);
        continue;
    end

    writetable(winners, fullfile(script_dir, sprintf('recovery_winners_%s_study%d.csv', outtag, study)));
    writetable(frequencies, fullfile(script_dir, sprintf('recovery_frequencies_%s_study%d.csv', outtag, study)));

    props = counts ./ max(sum(counts, 2), 1);
    T_c = array2table(counts, 'VariableNames', cellstr(model_names));
    T_c = addvars(T_c, cellstr(model_names)', 'Before', 1, 'NewVariableName', 'TrueModel');
    T_p = array2table(props, 'VariableNames', cellstr(model_names));
    T_p = addvars(T_p, cellstr(model_names)', 'Before', 1, 'NewVariableName', 'TrueModel');
    writetable(T_c, fullfile(script_dir, sprintf('recovery_confusion_counts_%s_study%d.csv', outtag, study)));
    writetable(T_p, fullfile(script_dir, sprintf('recovery_confusion_props_%s_study%d.csv', outtag, study)));

    rates = table(cellstr(model_names)', diag(counts) ./ sum(counts, 2), ...
                  sum(counts, 2), ...
                  'VariableNames', {'TrueModel', 'RecoveryRate', 'NIterations'});
    writetable(rates, fullfile(script_dir, sprintf('recovery_rates_%s_study%d.csv', outtag, study)));

    fprintf('\n=== Study %d (%d complete units) ===\n', study, height(winners));
    disp(rates);

    f = figure('Position', [100 100 560 480], 'Visible', 'off');
    imagesc(props);
    colormap(flipud(bone));
    colorbar;
    xticks(1:K); yticks(1:K);
    xticklabels(model_names); yticklabels(model_names);
    xlabel('Selected model (VBA XP winner)');
    ylabel('Generating model');
    title(sprintf('Model recovery, Study %d (n=%d units)', study, height(winners)));
    for ti = 1:K
        for fi = 1:K
            text(fi, ti, sprintf('%.2f', props(ti, fi)), ...
                 'HorizontalAlignment', 'center', 'Color', [.2 .2 .2]);
        end
    end
    exportgraphics(f, fullfile(script_dir, sprintf('recovery_confusion_figure_%s_study%d.png', outtag, study)), ...
                   'Resolution', 150);
    close(f);
end
