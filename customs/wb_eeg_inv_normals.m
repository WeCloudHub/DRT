function normal = wb_eeg_inv_normals(vert,face)
% Compute the normals of a mesh
% usage: normal = wb_eeg_inv_normals(vert,face)
%
% written by Li Dong (Lidong@uestc.edu.cn) $ 2020.4.1
% -------------------------------------------------------------------------
m = struct('Vertices',vert,'Faces',face);
h = figure('Visible','off');
try n = get(patch(m),'VertexNormals');catch;n = [];end;

if isempty(n)
    t = triangulation(double(face),double(vert));
    n = double(t.vertexNormal);
end
close(h);

f = sqrt(sum(n.^2,2));
I = find(f == 0);
for i = 1:length(I)
    n(I(i)) = n(I(i) - 1);
end
f           = sqrt(sum(n.^2,2));
normal(:,1) = n(:,1)./f;
normal(:,2) = n(:,2)./f;
normal(:,3) = n(:,3)./f;

return
%==========================================================================
