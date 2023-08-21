classdef ADgrid < Grid
    
    properties
        
        matrixOperators
        vectorHelpers
        
    end
    
    methods
        
        function gAD = ADgrid(G)

            gAD.G = G;
            gAD = gAD.setup();
            
        end

        function gAD = setup(gAD)

            G = gAD.G;
            
            switch G.griddim
              case 1
                gAD = gAD.setup1D();
              case 3
                gAD = gAD.setup3D();               
              otherwise
                error('Grid dimension not implemented yet.')
            end
            
       end

        function gAD = setup1D(gAD)

            G = gAD.G;
            
            nc = G.cells.num;
            nf = G.faces.num;
            nn = G.nodes.num; % In 1D, we have nn = nf

            celltbl.cells = (1 : nc)';
            celltbl = IndexArray(celltbl);

            facetbl.faces = (1 : nf)';
            facetbl = IndexArray(facetbl);
            
            nodetbl.nodes = (1 : nn)';
            nodetbl = IndexArray(nodetbl);

            cellfacetbl.cells = rldecode((1 : nc)', diff(G.cells.facePos));
            cellfacetbl.faces = G.cells.faces(:, 1);
            cellfacetbl = IndexArray(cellfacetbl);

            cellfacetbl2 = sortIndexArray(cellfacetbl, {'cells', 'faces'});
            faces = cellfacetbl2.get('faces');
            faces = reshape(faces, 2, [])';
            
            cellface12tbl.cells = (1 : nc)';
            cellface12tbl.faces1 = faces(:, 1);
            cellface12tbl.faces2 = faces(:, 2);
            cellface12tbl = IndexArray(cellface12tbl);
            
            % faceCentroids = nodeCoords

            prod = TensorProd();
            prod.tbl1 = cellfacetbl;
            prod.tbl2 = facetbl;
            prod.tbl3 = celltbl;
            prod.reducefds = {'faces'};
            prod = prod.setup();

            p = 0.5*ones(cellfacetbl.num, 1);

            tens = SparseTensor();
            tens = tens.setFromTensorProd(p, prod);

            matrixop.cellCentroids = tens.getMatrix();
            % To run:
            % cellCentroids = prod.eval(p, faceCentroids)

            %% Compute volumes(c, f1, f2) = abs(faceCentroids(f2) - faceCentroids(f1))*faceArea
            
            map1 = TensorMap();
            map1.fromTbl = facetbl;
            map1.toTbl = cellface12tbl;
            map1.replaceFromTblfds = {{'faces', 'faces1'}};
            map1.mergefds = {'faces1'};
            map1 = map1.setup();

            map2 = TensorMap();
            map2.fromTbl = facetbl;
            map2.toTbl = cellface12tbl;
            map2.replaceFromTblfds = {{'faces', 'faces2'}};
            map2.mergefds = {'faces2'};
            map2 = map2.setup();

            map3 = TensorMap();
            map3.fromTbl = cellface12tbl;
            map3.toTbl = celltbl;
            map3.mergefds = {'cells'};
            map3 = map3.setup();

            matrixop.vols1 = map1.getMatrix();
            matrixop.vols2 = map2.getMatrix();
            matrixop.vols3 = map3.getMatrix();
            % To run:
            % vols = map3.eval(map2.eval(faceCentroids) - map1.eval(faceCentroids))*faceArea

            %% Compute cellfacedist(c, f) = faceCentroids(f) - cellCentroids(c)
            
            map1 = TensorMap();
            map1.fromTbl = celltbl;
            map1.toTbl = cellfacetbl;
            map1.mergefds = {'cells'};
            map1 = map1.setup();
                        
            map2 = TensorMap();
            map2.fromTbl = facetbl;
            map2.toTbl = cellfacetbl;
            map2.mergefds = {'faces'};
            map2 = map2.setup();

            matrixop.cellfacedist1 = map1.getMatrix();
            matrixop.cellfacedist2 = map2.getMatrix();
            % To run:
            % cellfacedist = abs(map2.eval(faceCentroids) - map1.eval(cellCentroids))

            %% Compute hT(c, f) = 1/cellfacedist(c, f) * K(c) * faceArea
            prod = TensorProd();
            prod.tbl1 = cellfacetbl;
            prod.tbl2 = celltbl;
            prod.tbl3 = cellfacetbl;
            prod.mergefds = {'cells'};
            prod = prod.setup();

            matrixop.hT = prod.getMatrices;
            % To run:
            % hT = prod.eval(1./cellfacedist, K)*faceArea

            %% We compute transmissibility (only half transmissibility for the boundary faces)
            %% 1/h(f) = 1/h(c, f)

            map = TensorMap();
            map.fromTbl  = cellfacetbl;
            map.toTbl    = facetbl;
            map.mergefds = {'faces'};
            map = map.setup();

            matrixop.T = map.getMatrix();
            % To run:
            % T = 1./map.eval(1./hT);

            gAD.matrixOperators = matrixop;
            
        end
        
        function gAD = setup3D(gAD)

            G = gAD.G;
            
            nc = G.cells.num;
            nf = G.faces.num;
            nn = G.nodes.num;

            celltbl.cells = (1 : nc)';
            celltbl = IndexArray(celltbl);

            facetbl.faces = (1 : nf)';
            facetbl = IndexArray(facetbl);

            vectbl.vec = (1 : G.griddim)';
            vectbl = IndexArray(vectbl);

            nodetbl.nodes = (1 : nn)';
            nodetbl = IndexArray(nodetbl);

            cellfacetbl.cells = rldecode((1 : nc)', diff(G.cells.facePos));
            cellfacetbl.faces = G.cells.faces(:, 1);
            cellfacetbl = IndexArray(cellfacetbl);

            facenodetbl.faces = rldecode((1 : nf)', diff(G.faces.nodePos));
            facenodetbl.nodes = G.faces.nodes(:, 1);
            facenodetbl = IndexArray(facenodetbl);

            % Voigt setup

            val = [[1, 1, 1,
                    2, 2, 2,
                    3, 3, 3,
                    4, 2, 3,
                    5, 1, 3,
                    6, 1, 2]];

            voigttbl.voigt = val(:, 1);
            voigttbl = IndexArray(voigttbl);
            
            voigtvec12tbl.voigt = val(:, 1);
            voigtvec12tbl.vec1  = val(:, 2);
            voigtvec12tbl.vec2  = val(:, 3);
            voigtvec12tbl = IndexArray(voigtvec12tbl);

            gen = CrossIndexArrayGenerator();
            gen.tbl1 = vectbl;
            gen.tbl2 = vectbl;
            gen.replacefds1 = {{'vec', 'vec1'}};
            gen.replacefds2 = {{'vec', 'vec2'}};
            gen.mergefds = {};

            vec12tbl = gen.eval();
            
            % Triangles on the faces : facenode12tbl

            p = G.faces.nodePos;
            f = G.faces.nodes;
            next = (2 : size(f, 1) + 1) .';
            next(p(2 : end) - 1) = p(1 : end-1);
            nextf = f(next);

            facenode12tbl = replacefield(facenodetbl, {{'nodes', 'nodes1'}});
            facenode12tbl = facenode12tbl.addInd('nodes2', nextf);

            % sub-tetrahedra

            cellfacenode12tbl = crossIndexArray(cellfacetbl, facenode12tbl, {'faces'});

            % Variants that include spatial index

            facevectbl           = crossIndexArray(facetbl          , vectbl       , {}, 'optpureproduct', true);
            nodevectbl           = crossIndexArray(nodetbl          , vectbl       , {}, 'optpureproduct', true);
            cellvectbl           = crossIndexArray(celltbl          , vectbl       , {}, 'optpureproduct', true);
            cellfacevectbl       = crossIndexArray(cellfacetbl      , vectbl       , {}, 'optpureproduct', true);
            facenodevectbl       = crossIndexArray(facenodetbl      , vectbl       , {}, 'optpureproduct', true);
            facenode12vectbl     = crossIndexArray(facenode12tbl    , vectbl       , {}, 'optpureproduct', true);
            cellfacenode12vectbl = crossIndexArray(cellfacenode12tbl, vectbl       , {}, 'optpureproduct', true);
            cellvoigtvec12tbl    = crossIndexArray(celltbl          , voigtvec12tbl, {}, 'optpureproduct', true);
            cellvec12tbl         = crossIndexArray(celltbl          , vec12tbl     , {}, 'optpureproduct', true);
            
            % prepare output for some of the tables
            tbls = struct('celltbl'          , celltbl          , ...
                          'facetbl'          , facetbl          , ...
                          'vectbl'           , vectbl           , ...
                          'nodetbl'          , nodetbl          , ...
                          'cellfacetbl'      , cellfacetbl      , ...
                          'facenodetbl'      , facenodetbl      , ...
                          'voigtvec12tbl'    , voigtvec12tbl    , ...
                          'voigttbl'         , voigttbl         , ...
                          'cellvoigtvec12tbl', cellvoigtvec12tbl, ...
                          'vec12tbl'         , vec12tbl         , ...
                          'facevectbl'       , facevectbl       , ...
                          'nodevectbl'       , nodevectbl       , ...
                          'cellvectbl'       , cellvectbl       , ...
                          'cellfacevectbl'   , cellfacevectbl);
            
            % Setup pseudo face centroids : pseudoFaceCentroids(f) = noodeCoords(n, f)/number(n in f)

            map = TensorMap();
            map.fromTbl = nodevectbl;
            map.toTbl = facenodevectbl;
            map.mergefds = {'nodes', 'vec'};
            map = map.setup();

            matrixop.nodecoords_facenode = map.getMatrix();
            % To run:
            % nodecoords_facenode = map.eval(nodeCoords);  

            map = TensorMap();
            map.fromTbl = facenodevectbl;
            map.toTbl = facevectbl;
            map.mergefds = {'faces', 'vec'};
            map = map.setup();

            matrixop.facevec = map.getMatrix();
            % To run:
            % facevec = map.eval(nodecoords_facenode); % to be modified later
            
            map = TensorMap();
            map.fromTbl = facenodetbl;
            map.toTbl = facetbl;
            map.mergefds = {'faces'};
            map = map.setup();

            nnode_per_face = map.eval(ones(facenodetbl.num, 1));

            map = TensorMap();
            map.fromTbl = facetbl;
            map.toTbl = facevectbl;
            map.mergefds = {'faces'};
            map = map.setup();

            vechelps.nnode_per_face = map.eval(nnode_per_face);

            % To run:
            % pseudoFaceCentroids = facevec./nnode_per_face;

            %% Setup nfVector = nodeCoords - faceCentroids,  in triangle, belongs to nodefacevec

            map1          = TensorMap();
            map1.fromTbl  = facevectbl;
            map1.toTbl    = facenodevectbl;
            map1.mergefds = {'faces', 'vec'};
            map1          = map1.setup();

            map2          = TensorMap();
            map2.fromTbl  = nodevectbl;
            map2.toTbl    = facenodevectbl;
            map2.mergefds = {'nodes', 'vec'};
            map2          = map2.setup();

            matrixop.nfVector_1 = map1.getMatrix();
            matrixop.nfVector_2 = map2.getMatrix();
            % To Run:
            % nfVector = map2.eval(nodeCoords) - map1.eval(pseudoFaceCentroids); % belongs to facenodevectbl

            %% Setup normals, centers and areas of the triangles

            %% Setup the cross-product operator

            val = [2, 3, 1,  1
                   3, 2, 1, -1
                   1, 3, 2, -1
                   3, 1, 2,  1
                   1, 2, 3,  1
                   2, 1, 3, -1
                  ];

            permvec123tbl.vec1 = val(:, 1);
            permvec123tbl.vec2 = val(:, 2);
            permvec123tbl.vec3 = val(:, 3);
            permvec123tbl = IndexArray(permvec123tbl);

            sigma = val(:, 4); % belongs to permvec123tbl

            %% We start with the normals of the triangle : triNormals(n1, n2, f, i) = 1/2*(sum(sigma(i, j, k)*nfVector(n1, f, i)*nfVector(n2, f, j))

            map = TensorMap();
            map.fromTbl = facenodevectbl;
            map.toTbl = facenode12vectbl;
            map.replaceFromTblfds = {{'nodes', 'nodes1'}};
            map.mergefds = {'faces', 'nodes1', 'vec'};
            map = map.setup();

            matrixop.nfVector1 = map.getMatrix();
            % To run:
            % nfVector1 = map.eval(nfVector);
            
            map = TensorMap();
            map.fromTbl = facenodevectbl;
            map.toTbl = facenode12vectbl;
            map.replaceFromTblfds = {{'nodes', 'nodes2'}};
            map.mergefds = {'faces', 'nodes2', 'vec'};
            map = map.setup();

            matrixop.nfVector2 = map.getMatrix();
            % To run:
            % nfVector2 = map.eval(nfVector);

            prod = TensorProd();
            prod.tbl1 = permvec123tbl;
            prod.tbl2 = facenode12vectbl;
            prod.replacefds1 = {{'vec1', 'vec'}};
            prod.reducefds = {'vec'};
            prod = prod.setup();

            facenode12vec13tbl = prod.tbl3;

            M = SparseTensor();
            matrixop.triNormals1 = M.setFromTensorProd(sigma, prod);
            matrixop.triNormals1 = matrixop.triNormals1.getMatrix();
            % To Run:
            % triNormals = prod.eval(sigma, nfVector1); % temporary value

            prod = TensorProd();
            prod.tbl1 = facenode12vec13tbl;
            prod.tbl2 = facenode12vectbl;
            prod.tbl3 = facenode12vectbl;
            prod.replacefds1 = {{'vec3', 'vec'}};
            prod.replacefds2 = {{'vec', 'vec2'}};
            prod.reducefds = {'vec2'};
            prod.mergefds = {'faces', 'nodes1', 'nodes2'};
            prod = prod.setup();

            matrixop.triNormals = prod.getMatrices();
            % To run:
            % triNormals = 0.5*prod.eval(triNormals, nfVector2);

            %% We compute now the areas of the triangle : triAreas(n1, n2, f) = ( sum ( triNormals(n1, n2, f, i)*triNormals(n1, n2, f, i) ) )^(1/2)

            prod = TensorProd();
            prod.tbl1 = facenode12vectbl;
            prod.tbl2 = facenode12vectbl;
            prod.tbl3 = facenode12tbl;
            prod.reducefds = {'vec'};
            prod.mergefds = {'faces', 'nodes1', 'nodes2'};
            prod = prod.setup();

            matrixop.triAreas = prod.getMatrices();
            % To run:
            % triAreas = prod.eval(triNormals, triNormals);
            % triAreas = triAreas.^0.5;

            %% We compute the centroid of the triangle

            map = TensorMap();
            map.fromTbl = nodevectbl;
            map.toTbl = facenode12vectbl;
            map.replaceFromTblfds = {{'nodes', 'nodes1'}};
            map.mergefds = {'nodes1', 'vec'};
            map = map.setup();

            matrixop.n1Coords = map.getMatrix();
            % To run:
            % n1Coords = map.eval(nodeCoords);
            
            map = TensorMap();
            map.fromTbl = nodevectbl;
            map.toTbl = facenode12vectbl;
            map.replaceFromTblfds = {{'nodes', 'nodes2'}};
            map.mergefds = {'nodes2', 'vec'};
            map = map.setup();

            matrixop.n2Coords = map.getMatrix();
            % To run:
            % n2Coords = map.eval(nodeCoords);
            
            map = TensorMap();
            map.fromTbl = facevectbl;
            map.toTbl = facenode12vectbl;
            map.mergefds = {'faces', 'vec'};
            map = map.setup();

            matrixop.pseudoFaceCentroids = map.getMatrix();
            % To run:
            % pseudoFaceCentroids = map.eval(pseudoFaceCentroids);
            % and
            % triCentroids = (n1Coords + n2Coords + pseudoFaceCentroids)/3;

            %% We compute faceNormals(f, i) = sum( triNormals(n1, n2, f, i))

            map = TensorMap();
            map.fromTbl = facenode12vectbl;
            map.toTbl = facevectbl;
            map.mergefds = {'faces', 'vec'};
            map = map.setup();

            matrixop.faceNormals = map.getMatrix();
            % To run:
            % faceNormals = map.eval(triNormals);
            
            %% We compute faceAreas(f) = sum( triAreas(n1, n2, f))

            map = TensorMap();
            map.fromTbl = facenode12tbl;
            map.toTbl = facetbl;
            map.mergefds = {'faces'};
            map = map.setup();

            matrixop.faceAreas = map.getMatrix();
            % To run:
            % faceAreas = map.eval(triAreas);


            %% We compute the face centroids faceCentroids(f, i) = triCentroids(n1, n2, f, i)*triAreas(n1, n2, f)/faceAreas(f)

            prod = TensorProd();
            prod.tbl1 = facenode12vectbl;
            prod.tbl2 = facenode12tbl;
            prod.tbl3 = facevectbl;
            prod.mergefds = {'faces'};
            prod.reducefds = {'nodes1', 'nodes2'};
            prod = prod.setup();

            map = TensorMap();
            map.fromTbl = facetbl;
            map.toTbl = facevectbl;
            map.mergefds = {'faces'};
            map = map.setup();

            matrixop.faceCentroids1 = prod.getMatrices();
            matrixop.faceCentroids2 = map.getMatrix();
            % To run:
            % faceCentroids = prod.eval(triCentroids, triAreas)./map.eval(faceAreas);
            
            %% We compute pseudoCellCentroids(c, i) = sum(faceCentroids(f, i))/number_faces_per_cell

            map = TensorMap();
            map.fromTbl = facevectbl;
            map.toTbl = cellfacevectbl; 
            map.mergefds = {'faces', 'vec'};
            map = map.setup();

            matrixop.pseudoCellCentroids1 = map.getMatrix();
            % To run:
            % pseudoCellCentroids = map.eval(faceCentroids); % temporary value
            
            map = TensorMap();
            map.fromTbl = cellfacevectbl; 
            map.toTbl = cellvectbl;
            map.mergefds = {'cells', 'vec'};
            map = map.setup();

            matrixop.pseudoCellCentroids = map.getMatrix();
            % To run:
            % pseudoCellCentroids = map.eval(pseudoCellCentroids); % temporary value
            
            number_faces_per_cell = ones(cellfacevectbl.num, 1); % temporary values
            number_faces_per_cell = map.eval(number_faces_per_cell);

            vechelps.number_faces_per_cell = number_faces_per_cell;
            % To run:
            % pseudoCellCentroids = pseudoCellCentroids./number_faces_per_cell;

            %% We compute the scalar product : scalprod(f, c) = sum((faceCentroids(f, i) - pseudoCellCentroids(c, i))*faceNormals(f, i))

            map1 = TensorMap();
            map1.fromTbl = facevectbl;
            map1.toTbl = cellfacevectbl;
            map1.mergefds = {'faces', 'vec'};
            map1 = map1.setup();

            map2 = TensorMap();
            map2.fromTbl = cellvectbl;
            map2.toTbl = cellfacevectbl;
            map2.mergefds = {'cells', 'vec'};
            map2 = map2.setup();

            matrixop.scalprod1 = map1.getMatrix();
            matrixop.scalprod2 = map2.getMatrix();
            % To run
            % scalprod = (map1.eval(faceCentroids) - map2.eval(pseudoCellCentroids)).*map1.eval(faceNormals); % temporary value

            map = TensorMap();
            map.fromTbl = cellfacevectbl;
            map.toTbl = cellfacetbl;
            map.mergefds = {'cells', 'faces'};
            map = map.setup();

            matrixop.scalprod = map.getMatrix();
            % To run:
            % scalprod = map.eval(scalprod);
            % and
            % cellfacesign = (scalprod > 0) - (scalprod < 0);

            %% We compute the volumes of the tetrahedra :
            %% tetraVolumes(c, n1, n2, f)  = 1/3*sum((triCentroids(n1, n2, f, i) - pseudoCellCentroids(c, i))*cellfacesign(c, f)*triNormals(n1, n2, f, i))

            map1 = TensorMap();
            map1.fromTbl = facenode12vectbl;
            map1.toTbl = cellfacenode12vectbl;
            map1.mergefds = {'faces', 'nodes1', 'nodes2', 'vec'};
            map1 = map1.setup();

            map2 = TensorMap();
            map2.fromTbl = cellvectbl;
            map2.toTbl = cellfacenode12vectbl;
            map2.mergefds = {'cells', 'vec'};
            map2 = map2.setup();

            map3 = TensorMap();
            map3.fromTbl = cellfacetbl;
            map3.toTbl = cellfacenode12vectbl;
            map3.mergefds = {'cells', 'faces'};
            map3 = map3.setup();

            matrixop.tetraVolumes1 = map1.getMatrix();
            matrixop.tetraVolumes2 = map2.getMatrix();
            matrixop.tetraVolumes3 = map3.getMatrix();
            % To run:
            % tetraVolumes = 1/3*(map1.eval(triCentroids) - map2.eval(pseudoCellCentroids)).*map1.eval(triNormals).*map3.eval(cellfacesign);

            map = TensorMap();
            map.fromTbl = cellfacenode12vectbl;
            map.toTbl = cellfacenode12tbl;
            map.mergefds = {'cells', 'faces', 'nodes1', 'nodes2'};
            map = map.setup();

            matrixop.tetraVolumes = map.getMatrix();
            % To run:
            % tetraVolumes = map.eval(tetraVolumes);
            
            % We compute cell volumes cellVolumes(c) = sum( tetraVolumes(c, f, n1, n2))

            map = TensorMap();
            map.fromTbl = cellfacenode12tbl;
            map.toTbl = celltbl;
            map.mergefds = {'cells'};
            map = map.setup();

            matrixop.cellVolumes = map.getMatrix();
            % To run:
            % cellVolumes = map.eval(tetraVolumes);
            
            %% We adjust the centroids with relativeTetraCentroids(c, f, n1, n2, i) = 3/4*sum( triCentroids(f, n1, n2, i) - pseudoCellCentroids(c, i) )

            map1 = TensorMap();
            map1.fromTbl = facenode12vectbl;
            map1.toTbl = cellfacenode12vectbl;
            map1.mergefds = {'faces', 'nodes1', 'nodes2', 'vec'};
            map1 = map1.setup();

            map2 = TensorMap();
            map2.fromTbl = cellvectbl;
            map2.toTbl = cellfacenode12vectbl;
            map2.mergefds = {'cells', 'vec'};
            map2 = map2.setup();

            matrixop.relativeTetraCentroids1 = map1.getMatrix();
            matrixop.relativeTetraCentroids2 = map2.getMatrix();
            % To run:
            % relativeTetraCentroids = 3/4*(map1.eval(triCentroids) - map2.eval(pseudoCellCentroids));
            
            %% We define cellCentroids(c, i) = pseudoCellCentroids(c, i) + sum(relativeTetraCentroids(c, f, n1, n2, i)*tetraVolumes(c, f, n1, n2))/V(c)

            map1 = TensorMap();
            map1.fromTbl = cellfacenode12tbl;
            map1.toTbl = cellfacenode12vectbl;
            map1.mergefds = {'cells', 'faces', 'nodes1', 'nodes2'};
            map1 = map1.setup();

            map2 = TensorMap();
            map2.fromTbl = cellfacenode12vectbl;
            map2.toTbl = cellvectbl;
            map2.mergefds = {'cells', 'vec'};
            map2 = map2.setup();

            map3 = TensorMap();
            map3.fromTbl = celltbl;
            map3.toTbl = cellvectbl;
            map3.mergefds = {'cells'};
            map3 = map3.setup();

            matrixop.cellCentroids1 = map1.getMatrix();
            matrixop.cellCentroids2 = map2.getMatrix();
            matrixop.cellCentroids3 = map3.getMatrix();
            % To run:
            % cellCentroids = pseudoCellCentroids + map2.eval(relativeTetraCentroids.*map1.eval(tetraVolumes))./map3.eval(cellVolumes);

            %% Compute the half-transmissibility

            %% We compute d(c,f,i) = faceCentroids(f,i) - cellCentroids(c,i)

            map1 = TensorMap();
            map1.fromTbl = facevectbl;
            map1.toTbl = cellfacevectbl;
            map1.mergefds = {'faces', 'vec'};
            map1 = map1.setup();

            map2 = TensorMap();
            map2.fromTbl = cellvectbl;
            map2.toTbl = cellfacevectbl;
            map2.mergefds = {'cells', 'vec'};
            map2 = map2.setup();

            matrixop.d1 = map1.getMatrix();
            matrixop.d2 = map2.getMatrix();
            % To run:
            % d = map1.eval(faceCentroids) - map2.eval(cellCentroids)

            %% We map K to cellvec12tbl

            map = TensorMap();
            map.fromTbl = cellvoigtvec12tbl;
            map.toTbl = cellvec12tbl;
            map.mergefds = {'cells', 'vec1', 'vec2'};
            map = map.setup();

            matrixop.K = map.getMatrix();
            % To run:
            % K = map.eval(K)


            %% We compute the signed normals n(c, f, i) = cellfacesign(c, f)*faceNormals(f, i)
            
            prod = TensorProd();
            prod.tbl1 = cellfacetbl;
            prod.tbl2 = facevectbl;
            prod.tbl3 = cellfacevectbl;
            prod.mergefds = {'faces'};
            prod = prod.setup();

            matrixop.cellfaceNormals = prod.getMatrices();
            % To run:
            % cellfaceNormals = prod.eval(cellfacesign, faceNormals);
            
            %% We compute Kn(c, f, i) = K(c, i, j)*cellFaceNormals(c, f, j)

            prod = TensorProd();
            prod.tbl1 = cellvec12tbl;
            prod.tbl2 = cellfacevectbl;
            prod.tbl3 = cellfacevectbl;
            prod.replacefds1 = {{'vec1', 'vec'}};
            prod.replacefds2 = {{'vec', 'vec2'}};
            prod.mergefds = {'cells'};
            prod.reducefds = {'vec2'};
            prod = prod.setup();

            matrixop.Kn = prod.getMatrices();
            % To run:
            % Kn = prod.eval(K, cellfaceNormals);

            %% We compute:
            %% dKn(c, f) = d(c, f, i)*Kn(c, f, i),
            %% dsq(c, f) = d(c, f, i)*d(c, f, i),
            %% hT(c, f)  = dKn(c, f)/dsq(c, f)
            
            prod = TensorProd();
            prod.tbl1 = cellfacevectbl;
            prod.tbl2 = cellfacevectbl;
            prod.tbl3 = cellfacetbl;
            prod.mergefds = {'cells', 'faces'};
            prod.reducefds = {'vec'};
            prod = prod.setup();

            matrixop.dKn = prod.getMatrices();
            matrixop.dsq = matrixop.dKn; % for simplicity
                                         % To run:
                                         % dKn = prod.eval(d, Kn);
                                         % dsq = prod.eval(d, d);
                                         % hT = dKn./dsq;

            %% We compute transmissibility (only half transmissibility for the boundary faces)
            %% 1/h(f) = 1/h(c, f)

            map = TensorMap();
            map.fromTbl  = cellfacetbl;
            map.toTbl    = facetbl;
            map.mergefds = {'faces'};
            map = map.setup();

            matrixop.T = map.getMatrix();
            % To run:
            % T = 1./map.eval(1./hT);

            gAD.matrixOperators = matrixop;
            gAD.vectorHelpers   = vechelps;
            
        end

        function output = computeGeometryAndTrans(gAD, nodeCoords, K, faceArea)
            % Argument faceArea is only used for 1D case

            G = gAD.G;
            
            switch G.griddim
              case 1
                output = computeGeometryAndTrans1D(gAD, nodeCoords, K, faceArea);
              case 3
                output = computeGeometryAndTrans3D(gAD, nodeCoords, K);
              otherwise
                error('Grid dimension not implemented yet.')
            end
            
        end
        
        function output = computeGeometryAndTrans1D(gAD, nodeCoords, K, faceArea)
            
            m  = gAD.matrixOperators;
            G  = gAD.G;
            nf = G.faces.num;

            faceCentroids = nodeCoords;

            cellCentroids = m.cellCentroids*faceCentroids;
            
            cellVolumes = m.vols3*(abs(m.vols2*faceCentroids - m.vols1*faceCentroids))*faceArea;
            
            G.cells.volumes   = cellVolumes;
            G.cells.centroids = cellCentroids;

            G.faces.areas     = faceArea*ones(nf, 1);
            G.faces.normals   = G.faces.areas;
            G.faces.centroids = faceCentroids;

            G.nodes.coords = nodeCoords;

            cellfacedist = abs(m.cellfacedist2*faceCentroids - m.cellfacedist1*cellCentroids);

            hT = ADgrid.applyProduct(m.hT, 1./cellfacedist, K);
            hT = faceArea*hT;
            
            T = 1./(m.T*(1./hT));
            
            output = struct('G' , G , ...
                            'hT', hT, ...
                            'T' , T);

        end
        
        function output = computeGeometryAndTrans3D(gAD, nodeCoords, K)
            
            m = gAD.matrixOperators;
            v = gAD.vectorHelpers;
            G = gAD.G;
            
            n = G.griddim;
            
            nodecoords_facenode = m.nodecoords_facenode*nodeCoords;
            facevec             = m.facevec*nodecoords_facenode;
            pseudoFaceCentroids = facevec./v.nnode_per_face;
            
            nfVector  = m.nfVector_2*nodeCoords - m.nfVector_1*pseudoFaceCentroids; 

            nfVector1 = m.nfVector1*nfVector;
            nfVector2 = m.nfVector2*nfVector;
            
            triNormals = m.triNormals1*nfVector1;
            triNormals = 0.5*gAD.applyProduct(m.triNormals, triNormals, nfVector2);

            triAreas = gAD.applyProduct(m.triAreas, triNormals, triNormals);
            triAreas = triAreas.^0.5;
            
            n1Coords       = m.n1Coords*nodeCoords;
            n2Coords       = m.n2Coords*nodeCoords;
            pseudoFaceCentroids = m.pseudoFaceCentroids*pseudoFaceCentroids;

            triCentroids = (n1Coords + n2Coords + pseudoFaceCentroids)/3;

            faceNormals = m.faceNormals*triNormals;
            faceAreas   = m.faceAreas*triAreas;

            D1 = m.faceCentroids1.D1;
            D2 = m.faceCentroids1.D2;
            S  = m.faceCentroids1.S;            

            faceCentroids = (S*((D1*triCentroids).*(D2*triAreas)))./(m.faceCentroids2*faceAreas);
            
            pseudoCellCentroids = m.pseudoCellCentroids1*faceCentroids;
            pseudoCellCentroids = m.pseudoCellCentroids*pseudoCellCentroids;
            pseudoCellCentroids = pseudoCellCentroids./v.number_faces_per_cell;

            scalprod = (m.scalprod1*faceCentroids - m.scalprod2*pseudoCellCentroids).*(m.scalprod1*faceNormals);
            scalprod = m.scalprod*scalprod;
            scalprod = value(scalprod);
            cellfacesign = (scalprod > 0) - (scalprod < 0);
            
            tetraVolumes           = 1/3*(m.tetraVolumes1*triCentroids - m.tetraVolumes2*pseudoCellCentroids).*(m.tetraVolumes1*triNormals).*(m.tetraVolumes3*cellfacesign);
            tetraVolumes           = m.tetraVolumes*tetraVolumes;
            cellVolumes            = m.cellVolumes*tetraVolumes;
            relativeTetraCentroids = 3/4*(m.relativeTetraCentroids1*triCentroids - m.relativeTetraCentroids2*pseudoCellCentroids);
            
            cellCentroids = pseudoCellCentroids + (m.cellCentroids2*(relativeTetraCentroids.*(m.cellCentroids1*tetraVolumes)))./(m.cellCentroids3*cellVolumes);

            G.cells.volumes   = cellVolumes;
            G.cells.centroids = cellCentroids;

            G.faces.areas     = faceAreas;
            G.faces.normals   = faceNormals;
            G.faces.centroids = faceCentroids;

            G.nodes.coords = nodeCoords;

            % Computation of transmissibilities
            
            d = m.d1*faceCentroids - m.d2*cellCentroids;
            K = m.K*K;

            cellfaceNormals = gAD.applyProduct(m.cellfaceNormals, cellfacesign, faceNormals);
            
            Kn  = gAD.applyProduct(m.Kn, K, cellfaceNormals);
            dKn = gAD.applyProduct(m.dKn, d, Kn);
            dsq = gAD.applyProduct(m.dsq, d, d);

            hT = dKn./dsq;

            T = 1./(m.T*(1./hT));

            output = struct('G' , G , ...
                            'hT', hT, ...
                            'T' , T);

        end
        
    end

    methods(Static)

        function value = applyProduct(matrixOperator, arg1, arg2)

            D1 = matrixOperator.D1;
            D2 = matrixOperator.D2;
            S  = matrixOperator.S;

            value = S*((D1*arg1).*(D2*arg2));
            
        end
    end
    
    
end
