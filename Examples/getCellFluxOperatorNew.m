function op = getCellFluxOperatorNew(G,varargin)
    internal = all(G.faces.neighbors>0,2)
    faces = find(internal);
    nfi=sum(internal)
    faces_hf = rldecode(faces,2);
    ifaces_hf = rldecode([1:nfi]',2);
    map = [reshape(G.faces.neighbors(internal,:)',[],1),faces_hf,ifaces_hf]
    [smap,i] = sortrows(map);
    %%
    nc = G.cells.num;
    dims = G.griddim
    m=accumarray(smap(:,1),1,[nc,1])
    n=G.griddim*ones(nc,1);
    [I,J] = blockDiagIndex(n,m)
    N=G.faces.normals(smap(:,2),:);
    sign = 2*(smap(:,1)==G.faces.neighbors(smap(:,2),1))-1;
    NN=bsxfun(@times,N,sign);
    N=sparse(I,J,reshape(NN',[],1))'%size(smap,1),dims*nc);
    %%
    opt = struct('invertBlocks','matlab');
    opt = merge_options(opt,varargin{:});
    bi = blockInverter(opt)
    NTN = N'*N;
    NTNinv=bi(NTN,n);
    %%
    f2hf=sparse(i,smap(:,3),sign,size(map,1),nfi);
    P = NTNinv*N'*f2hf;
    S = sparse(rldecode(1:nc,dims),[1:dims*nc]',1,nc,dims*nc);
    op = struct('S',S,'P',P)
end