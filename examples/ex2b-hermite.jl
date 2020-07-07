# # An equation of forth order in one dimmension
#
# Consider the following problem. Given \\(f \in C([0, 1])\\), find a function \\(u\\) satisfying
# u'''' = f in (0, 1)
# u(0) = u(1) = 0
# u'(0) = pi; u'(1) = pi

using FEMTools
using SymPy
using LinearAlgebra
using SparseArrays
using PyPlot
close("all")

# discretization parameters
N = 101; # number of nodes
dx = 1 / (N - 1); # discretization step
nodes = range(0, stop=1, length=N);
bound_nodes = [1, N];

# exact solution
u_exact = sin.(pi*nodes);
ud_exact = pi * cos.(pi*nodes)
# right hand 
f = pi^4 * sin.(pi * nodes);
fd = pi^5 * cos.(pi * nodes);
ff = zeros(2*N);
ff[1:2:2*N-1] = f;
ff[2:2:2*N] = fd;

# symbols 
x = SymPy.symbols("x");
h = SymPy.symbols("h");

# elementary matrices
elem_K = FEMTools.get_hermite_em(3, 2, 2);
elem_M = FEMTools.get_em(3, 3, 0, 0; fe1="Hermite", fe2="Hermite")
elem_K_dx = convert(Matrix{Float64}, elem_K.subs(h, dx));
elem_M_dx = convert(Matrix{Float64}, elem_M.subs(h, dx));

K = FEMTools.assemble_1d_FE_matrix(elem_K_dx, N, intNodes=0, dof1=2, dof2=2);
M = FEMTools.assemble_1d_FE_matrix(elem_M_dx, N, intNodes=0, dof1=2, dof2=2);

F = M * ff;

# boundary conditions
tgv = 1e100
KB = copy(K)
KB[2*bound_nodes .- 1, 2*bound_nodes .- 1] += tgv*sparse(Matrix{Float64}(I, 2, 2));
KB[2*bound_nodes, 2*bound_nodes] += tgv*sparse(Matrix{Float64}(I, 2, 2));

F[2*bound_nodes .- 1] = zeros(2);
F[2] = pi*tgv
F[2*N] = -pi*tgv

u = KB \ F;

plot(nodes, u_exact);
plot(nodes, u[1:2:2*N-1]);
legend(["Exact solution", "Approximate solution"]);

U_exact = zeros(2*N)
U_exact[1:2:2*N-1] = u_exact
U_exact[2:2:2*N] = ud_exact
err = u - U_exact;
println("H1 error = ", sqrt(err' * K * err))
