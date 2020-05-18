% Matlab codes to generate undirected network file from earth observation or species occurance data for Louvain and Infomap.
% Shengli Tao. 2018. sltao1990@gmail.com

clc
clear

load 1km_16layers_earth_observation %%%% Each row is a pixel, each colum is an earth observation variable (temperature, precipitation, EVI......),
%%%%  Similarly, the input data can be a species occurance matrix: each row is a pixel, and each colum an occurance record (0,1) for one species 


%% knn first
tic;
knn_k=400; %%% 400 should be enough
[idx,dist]= knnsearch(all_tif_layers_zscore,all_tif_layers_zscore,'K',knn_k,'NSMethod','kdtree');  %%% Jaccard distance if for species data:'Distance','jaccard'
toc;

idx(:,1)=[];
dist(:,1)=[];

save('1km_16layers_k399_idx_CPU.mat','idx','-v7.3')
disp('saved idx...')
clear dist

%% Adaptive Nearest Neighbors (ANN) search technique from Ziemann et al. (2014)
%%%% Ziemann AK, Messinger DW, Wenger PS (2014) An adaptive k-nearest neighbor graph building technique with 
%%%% applications to hyperspectral imagery. In Proceedings of the 2014 IEEE WNY Image Processing Workshop, IEEE.

nb_k=zeros(size(idx,1),1);

NB0_k_all={};

for i=1:size(idx,2)

    nb_k_temp=histc(idx(:,i),1:size(idx,1));    
    nb_k=nb_k+nb_k_temp;
    
    NB0_k=find(nb_k==0);
    
    NB0_k_all{i}=NB0_k;
    
    if i>1
        if (sum(nb_k==0))==0 || isequal(NB0_k_all{i},NB0_k_all{i-1})
            disp(i)
            break
        end
    end
    
  
end

disp(max(nb_k))

% save('nb_k_1km_16layers_k399_idx','nb_k','-v7.3')

sum(nb_k==0)
nb_k(nb_k==0)=1;

idx_chose=uint32(idx(:,1:max(nb_k)));
% dist_chose=dist(:,1:max(nb_k));
clear idx 

temp_ind = bsxfun(@le, cumsum(ones(size(idx_chose)), 2), nb_k); 
idx_chose=idx_chose.*uint32(temp_ind);
% dist_chose=dist_chose.*temp_ind;

clear temp_ind
% maxdistance=double(max(dist_chose(:)));

network_list=zeros(size(idx_chose,1)*(size(idx_chose,2)),3,'uint32');

disp('for_loop.....')
tic
for j=1:size(idx_chose,2)

    source_node=(1:size(idx_chose,1))';
    sink_node=idx_chose(:,j);
    
%     weight_node=1-double(dist_chose(:,j))/maxdistance;  %%% weight based on distance. Complicated.
    weight_node=ones(length(sink_node),1,'uint32');

    xx=j;
    network_list((xx-1)*size(idx_chose,1)+1:xx*size(idx_chose,1),:)=[source_node sink_node weight_node];
    
end
toc

clear idx_chose  dist_chose 
network_list(network_list(:,2)==0,:)=[];

%% delete repeative links to reduce file size
[~,tempidx2] = unique(sort(network_list(:,[1 2]),2),'rows','stable');
network_list = network_list(tempidx2,:);

%%
disp('write txt......')
network_list(:,3)=[]; % for Louvain. Keep colum 3 for if for Infomap
outtxt_name2=strcat('./gen-louvain/input/1km_16layers_k399_CPU.txt');
tic
fileID = fopen(outtxt_name2,'w');
fprintf(fileID,'%d %d\n',network_list');
fclose(fileID);
toc

% cd('/home/data/STao_LidarNearestPoints/gen-louvain')

