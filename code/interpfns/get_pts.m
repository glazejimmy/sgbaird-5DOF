function pts = get_pts(qm,nA)
% GET_PTS  get symmetrized octonions from qm/nA pairs
pts = get_octpairs(GBfive2oct(qm,nA));
end