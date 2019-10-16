classdef p2p_distance < cube_ROIs
    methods
        function [D, R, S, A] = distances(obj, MinPeakProminence)
            switch nargin
                case 2
                    obj.MinPeakProminence = MinPeakProminence;                
            end
%             obj.C.load_data % todo make this a method again
            
            D = []; R = []; S = []; A = [];
            
            j = 1;
            for i = 1:length(obj.ROIs)
                [locs, pks] = obj.ROIs{i}.get_peaks(obj.MinPeakProminence);
                
                if length(locs) > 1
                    % Get all combination distances
                    positions = combnk(locs, 2);
                    intensities = combnk(pks, 2);

                    [combos,~] = size(positions);
                    Di = zeros(1,combos); Ri = zeros(1,combos); Si = zeros(1,combos); Ai = zeros(1,combos);

                    for combo = 1:combos
                        dist = positions(combo,:);
                        inty = intensities(combo,:);
                        Di(combo) = abs(single(obj.z(dist(1))) - single(obj.z(dist(2))))*1e-3;
                        Ri(combo) = single(max(inty)) / single(min(inty));
                        Si(combo) = i;
                        j = j+1;
                    end

                    D = [D, Di]; R = [R, Ri]; S = [S, Si]; A = [A, Ai];
                end
            end            
        end
        
        function [Df, Rf, Sf, Af] = filtered_distances(obj, MinPeakProminence)
            switch nargin
                case 2
                    obj.MinPeakProminence = MinPeakProminence;                
            end
            
            [D,R,S,A] = obj.distances(obj.MinPeakProminence);
            
            Sf = []; Sm = [];
            
            for i = 1:max(S)
                if sum(S == i) > 1
                    Sm = [Sm, i];
                elseif sum(S == i) == 1
                    Sf = [Sf, i];
                end
            end
            
            if isempty(Sf)
                disp('There are no single-length observations (or none at all)')
            end
            if ~isempty(Sm)
                try
                    [~,idx] = intersect(S,Sf);
                    Df = D(idx); Rf = R(idx); Af = A(idx);
                catch
                    disp('Something is wrong')
                end

                distribution = D(idx);
                for m = Sm
                    outs = D(S == m);
                    [~, order] = sort(abs(outs - median(distribution)));

                    Df = [Df, outs(order(1))]; Rf = [Rf, R(order(1))]; Af = [Af, A(order(1))]; % todo: indeces not right
                end
            else
                Df = D; Rf = R; Sf = S; Af = A;
            end

            
        end
        
        function profiles(obj)
            figure;
            obj.C.load_data
            zz = (single(obj.z)-single(obj.z(1)))*1e-3;            
            
            for i = 1:length(obj.ROIs)
                plot(zz, normalize(obj.ROIs{i}.profile))
                hold on
            end    
            
            legend;
            xlabel('Z-position (µm')
            ylabel('Average intensity (a.u.)')
            xlim(single([0, max(zz)]))
        end
        
        function [D,R,clusters,centroids] = cluster(obj, ClusterN, Cluster2D, MinPeakProminence)
            switch nargin
                case 1
                    ClusterN = 3;
                    Cluster2D = false;
                    obj.MinPeakProminence = 0.1;
                case 2
                    Cluster2D = false;
                    obj.MinPeakProminence = 0.1;
                case 3
                    obj.MinPeakProminence = 0.1;
                case 4
                    obj.MinPeakProminence = MinPeakProminence;
            end
            figure;
            obj.C.load_data
             
            [D,R,S] = obj.distances(obj.MinPeakProminence);
            if ~isempty(D)
                maxD = 1.05*max(D); maxR = 1.05*max(R);
            else
                maxD = 10; maxR = 10;
            end
            
            colors = cbrewer('qual', 'Accent', ClusterN);
            
            if length(D) > ClusterN % i.e. some ROIs may not have a D entry after all...
                if Cluster2D
                    [clusters, centroids] = kmeans([D',R'], ClusterN); % Cluster by distance & relative intensity
                    scatter(centroids(:,1), centroids(:,2), 150, 'kx')
                    hold on
                else
                    [clusters, centroids] = kmeans(D', ClusterN); % Cluster by distance only (more robust)
                end

                for i = 1:length(D)
                    scatter(D(i), R(i), ...
                        'MarkerFaceColor', colors(clusters(i),:), 'MarkerEdgeColor', colors(clusters(i),:))
                    text(D(i)+0.25, R(i)+0.25, {num2str(S(i))});
                    hold on
                end

                for cluster = 1:ClusterN
                    plot([centroids(cluster,1), centroids(cluster,1)],  [0, maxR], 'LineStyle', '--', 'Color', colors(cluster,:))
                    hold on
                end
            else
                for i = 1:length(D)
                    scatter(D(i), R(i), ...
                        'MarkerFaceColor', colors(1,:), 'MarkerEdgeColor', colors(1,:))
                    text(D(i)+0.25, R(i)+0.25, {num2str(S(i))});
                    hold on
                end
            end

            xlabel('Distance (µm)')
            ylabel('Relative intensity (a.u.)')
            xlim([0, maxD])
            ylim([0, maxR])
        end
    end
    
end
