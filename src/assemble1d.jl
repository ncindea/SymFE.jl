# todo : document and add some other nasty functions
using SparseArrays

"""
    Mesh1d

A type describing a mesh for a one dimensional domain.
"""
struct Mesh1d
    nodes::Array{Float64, 1}
    elements::Array{Int64, 2}
end

"""
    assemble_1d_FE_matrix(elem::Array{Float64, 2}, nbNodes::Int64;
      intNodes = 0, dof1 = 1, dof2 = 1)

Assemble a finite elements matrix corresponding to a 1 dimensional uniform mesh.

# Arguments
  * `elem` : elementary finite elements matrix
  * `nbNodes` : number of nodes in the mesh
  * `intNodes1` : number of interior nodes in the interior of each element for lhs
  * `intNodes2` : number of interior nodes in the interior of each element for rhs
  * `dof1`     : number of degrees of freedom for each node for lhs
  * `dof2`     : number of degrees of freedom for each node for rhs
"""
function assemble_1d_FE_matrix(elem::Array{Float64, 2}, nbNodes::Int64;
                               intNodes1 = 0, intNodes2 = 0, dof1 = 1, dof2 = 1)

    nT = Threads.nthreads()
    
    nbNodesTotal1 = (nbNodes + (nbNodes - 1) * intNodes1)
    nbNodesTotal2 = (nbNodes + (nbNodes - 1) * intNodes2)

    MM = Array{SparseMatrixCSC{Float64,Int64}}(undef, nT)
    for i = 1:nT
        MM[i] = spzeros(Float64, nbNodesTotal1 * dof1, nbNodesTotal2 * dof2)
    end

    l1 = zeros(UInt64, nT)
    r1 = zeros(UInt64, nT)
    l2 = zeros(UInt64, nT)
    r2 = zeros(UInt64, nT)
    

    Threads.@threads for i = 1:(nbNodes - 1)
        k = Threads.threadid()
        
        l1[k] = (i - 1 + (i - 1) * intNodes1) * dof1 + 1
        r1[k] = (i + 1 + i * intNodes1) * dof1
        l2[k] = (i - 1 + (i - 1) * intNodes2) * dof2 + 1
        r2[k] = (i + 1 + i * intNodes2) * dof2
        MM[k][l1[k]:r1[k], l2[k]:r2[k]] += elem
    end
    M = MM[1]
    for i=2:nT
        M += MM[i]
    end
    M
end

"""
    assemble_1d_nu_FE_matrix_varcoeff(elem::Matrix{SymPy.Sym}, nodes::Array{Float64, 1};
      intNodes = 0, dof1 = 1, dof2 = 1)

Assemble a finite elements matrix corresponding to a 1 dimensional non-uniform mesh.

# Arguments
  * `elem` : elementary finite elements matrix (with elements of type SymPy.Sym)
  * `nodes` : vector of nodes composing the non uniform-mesh
  * `intNodes1` : number of interior nodes in the interior of each element for lhs
  * `intNodes2` : number of interior nodes in the interior of each element for rhs
  * `dof1`     : number of degrees of freedom for each node for lhs
  * `dof2`     : number of degrees of freedom for each node for rhs
"""
function assemble_1d_nu_FE_matrix_varcoeff(elem::Matrix{SymPy.Sym}, nodes::Array{Float64, 1};
                                  intNodes1 = 0, intNodes2 = 0, dof1 = 1, dof2 = 1)

    nT = Threads.nthreads()
    global xa
    global xb
    nbNodes = length(nodes)
    nbNodesTotal1 = (nbNodes + (nbNodes - 1) * intNodes1)
    nbNodesTotal2 = (nbNodes + (nbNodes - 1) * intNodes2)

    MM = Array{SparseMatrixCSC{Float64,Int64}}(undef, nT)
    for i = 1:nT
        MM[i] = spzeros(Float64, nbNodesTotal1 * dof1, nbNodesTotal2 * dof2)
    end

    l1 = zeros(UInt64, nT)
    r1 = zeros(UInt64, nT)
    l2 = zeros(UInt64, nT)
    r2 = zeros(UInt64, nT)
    Threads.@threads for i = 1:nbNodes - 1
        k = Threads.threadid()
        l1[k] = (i - 1 + (i - 1) * intNodes1) * dof1 + 1
        r1[k] = (i + 1 + i * intNodes1) * dof1
        l2[k] = (i - 1 + (i - 1) * intNodes2) * dof2 + 1
        r2[k] = (i + 1 + i * intNodes2) * dof2
        elem_loc = elem.subs([(xa, nodes[i]), (xb, nodes[i+1])])
        elem_loc = convert(Matrix{Float64}, elem_loc)
        MM[k][l1[k]:r1[k], l2[k]:r2[k]] += elem_loc
    end
    M = MM[1]
    for i=2:nT
        M += MM[i]
    end
    M
end

"""
    assemble_1d_nu_FE_matrix(elem::Matrix{SymPy.Sym}, nodes::Array{Float64, 1};
      intNodes = 0, dof1 = 1, dof2 = 1)

Assemble a finite elements matrix corresponding to a 1 dimensional non-uniform mesh.

# Arguments
  * `elem` : elementary finite elements matrix (with elements of type SymPy.Sym)
  * `nodes` : vector of nodes composing the non uniform-mesh
  * `intNodes1` : number of interior nodes in the interior of each element for lhs
  * `intNodes2` : number of interior nodes in the interior of each element for rhs
  * `dof1`     : number of degrees of freedom for each node for lhs
  * `dof2`     : number of degrees of freedom for each node for rhs
"""
function assemble_1d_nu_FE_matrix(elem::Matrix{SymPy.Sym}, nodes::Array{Float64, 1};
                                  intNodes1 = 0, intNodes2 = 0, dof1 = 1, dof2 = 1)

    nT = Threads.nthreads()
    global h  
    nbNodes = length(nodes)
    nbNodesTotal1 = (nbNodes + (nbNodes - 1) * intNodes1)
    nbNodesTotal2 = (nbNodes + (nbNodes - 1) * intNodes2)

    MM = Array{SparseMatrixCSC{Float64,Int64}}(undef, nT)
    for i = 1:nT
        MM[i] = spzeros(Float64, nbNodesTotal1 * dof1, nbNodesTotal2 * dof2)
    end

    l1 = zeros(UInt64, nT)
    r1 = zeros(UInt64, nT)
    l2 = zeros(UInt64, nT)
    r2 = zeros(UInt64, nT)
    Threads.@threads for i = 1:nbNodes - 1
        k = Threads.threadid()
        l1[k] = (i - 1 + (i - 1) * intNodes1) * dof1 + 1
        r1[k] = (i + 1 + i * intNodes1) * dof1
        l2[k] = (i - 1 + (i - 1) * intNodes2) * dof2 + 1
        r2[k] = (i + 1 + i * intNodes2) * dof2
        elem_loc = elem.subs(h, nodes[i + 1] - nodes[i])
        MM[k][l1[k]:r1[k], l2[k]:r2[k]] += elem_loc
    end
    M = MM[1]
    for i=2:nT
        M += MM[i]
    end
    M
end
