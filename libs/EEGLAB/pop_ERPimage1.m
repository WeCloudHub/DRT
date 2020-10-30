% pop_erpimage() - draw an ERP-image plot of a given epoched EEG data.
% Input:
%     epochedEEG: Epoched EEG data. trails X timepoints of a epoch.
%     epochRange: Epoch time range.(ms) (optional)
%     srate:      sampling rate (Hz). (optional)
%     titlename: title. (optional).
%     weights:   IC weights.channels X 1.(optinal)
%     chanlocs: channel locations. see EEG.channslocs (optional)
% -------------------------------------------------------------------------
% Written by Li Dong (2015/9/28).
% Li_dong729@163.com
function  pop_ERPimage1(epochedEEG,epochRange,srate,titlename,weights,chanlocs)
if nargin < 1
    error('At least 1 inputs.');
elseif nargin == 1 || nargin == 2
    flag1 = 0; % unit of ERP time is ms?
    flag2 = 0; % plot topo?
    flag3 = 0; % baseline correction?
    titlename = [];
elseif nargin == 3 
    flag1 = 1;
    flag2 = 0;
    flag3 = 1;
    titlename = [];
elseif nargin == 4 
    flag1 = 1;
    flag2 = 0;
    flag3 = 1;
elseif nargin == 5 || nargin == 6
    flag1 = 1;
    flag2 = 1;
    flag3 = 1;
end


figure;
if flag2 == 1
    % topo
    subplot(3,1,1);
    topoplot(weights,chanlocs, 'maplimits', [min(weights), max(weights)],'style','both');
    colorbar;
    title('Topograph');
    
    % trials
    subplot(3,1,2);
    normEEG = (epochedEEG - max(epochedEEG(:)))/(max(epochedEEG(:))-min(epochedEEG(:))); % normlize to 0-1
    imagesc(normEEG);
    xlabel('timepoints');
    ylabel('trials');
    if flag1 == 1
        xtick_a= 0:round(abs(epochRange(1))/1000*srate):size(epochedEEG,2);
        xlim([0 size(epochedEEG,2)]);
        set(gca,'xtick',xtick_a);
    end
    title('Trials');
    % ERP
    subplot(3,1,3);
    meanERP = mean(epochedEEG,1);
    if flag3 == 1
        t1 = round(abs(epochRange(1))/1000*srate);
        temp1 = meanERP(1:max(1,t1));
        plot(meanERP-mean(temp1(:)),'-k','linewidth',1.2);
    else
        plot(meanERP,'-k','linewidth',1.2);
    end
    if flag1 == 1
        t1 = round(abs(epochRange(1))/1000*srate);
        y1 = linspace(min(meanERP(:))-1,max(meanERP(:))+1);
        hold on; plot(ones(length(y1),1).*t1,y1,'-k','linewidth',1.5);hold off;
        xlim([0 length(meanERP)]);
        ylim([min(meanERP(:))-1,max(meanERP(:))+1]);
        xlabel('time(ms)');
        xtick_a= 0:round(abs(epochRange(1))/1000*srate):length(meanERP);
        xticklabel_a = 1000.*(xtick_a./srate)-abs(epochRange(1));
        set(gca,'xtick',xtick_a);
        set(gca,'xticklabel',xticklabel_a);
    else
        xlabel('timepoints');
    end
    ylabel('weights');
    title(['ERP-',titlename],'Fontweight','Bold');
else 
    % trials
    subplot(2,1,1);
    % normEEG = (epochedEEG - repmat(mean(epochedEEG,2),1,size(epochedEEG,2)))./repmat(std(epochedEEG,0,2),1,size(epochedEEG,2));
    normEEG = (epochedEEG - max(epochedEEG(:)))/(max(epochedEEG(:))-min(epochedEEG(:))); % normlize to 0-1
    imagesc(normEEG);
    xlabel('timepoints');
    ylabel('trials');
    title(['ERP-',titlename],'Fontweight','Bold');
    
    % ERP
    subplot(2,1,2);
    meanERP = mean(epochedEEG,1);
    plot(meanERP,'-k','linewidth',1.2);
    if flag1 == 1
        t1 = round(abs(epochRange(1))/1000*srate);
        y1 = linspace(min(meanERP(:))-1,max(meanERP(:))+1);
        hold on; plot(ones(length(y1),1).*t1,y1,'-k','linewidth',1.5);hold off;
        xlim([0 length(meanERP)]);
        ylim([min(meanERP(:))-1,max(meanERP(:))+1]);
        xlabel('time(ms)');
        xtick_a= 0:round(abs(epochRange(1))/1000*srate):length(meanERP);
        xticklabel_a = 1000.*(xtick_a./srate)-abs(epochRange(1));
        set(gca,'xtick',xtick_a);
        set(gca,'xticklabel',xticklabel_a);
    else
        xlabel('timepoints');
    end
    ylabel('weights');
end
    
