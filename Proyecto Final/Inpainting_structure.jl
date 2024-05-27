# Import libraries

# using Pkg
# Pkg.add("Images")
# Pkg.add("FileIO")
# Pkg.add("Plots")


using Images
using FileIO
using Plots

image_folder = "Proyecto Final/Images"
mickey_path = joinpath(image_folder, "Mickey.jpg")
Omega_path = joinpath(image_folder, "Mask_lorem_ipsum.jpg")

function anisotropic_iteration(
    I_0::Array{Float64, 2};
    K::Float64 = 0.05,
    dt::Float64 = 1/20,
    )::Array{Float64, 2}

    if !(0<dt<1/4)
        throw(ArgumentError("dt debe estar entre 0 y 1/4"))
    end

    # Inicializamos el siguiente I_n
    In_siguiente = copy(I_0)
    In = copy(I_0)

    function g(x::Float64)::Float64
        return exp(-x^2 / K^2)
    end

    for (i, j) in Iterators.product(1:size(In, 1), 1:size(In, 2))

        # N-> Norte, S-> Sur, E-> Este, O-> Oeste

        # Ecuación 8
        # Diferencias a los vecinos más cercanos
        DNIn = In[max(i-1, 1), j] - In[i,j]
        DSIn = In[min(i+1, size(In, 1)), j] - In[i,j]
        DEIn = In[i, min(j+1, size(In, 2))] - In[i,j]
        DOIn = In[i, max(j-1, 1)] - In[i,j]

        # Ecuación 10
        # Coeficientes de conducción (aproximados)
        cNn = g(DNIn)
        cSn = g(DSIn)
        cEn = g(DEIn)
        cOn = g(DOIn)

        # Ecuación 7
        # Discretisación de 4 vecinos cercanos de Laplaceano
        L = cNn * DNIn + cSn * DSIn + cEn * DEIn + cOn * DOIn
        In_siguiente[i, j] = In[i, j] + dt * L
    end
    In = copy(In_siguiente)
    return In
end

function inpaint_iteration(
    In::Array{Float64, 2},
    Omega::BitMatrix,
    dt::Float64,
    eps::Float64,
    )::Array{Float64, 2}
    # Inicializamos el siguiente I_n
    In_siguiente = copy(In)

    # Ecuación 8
    function L(I, i, j)
        Inxx = I[i-1, j] - 2 * I[i, j] + I[i+1, j]
        Inyy = I[i, j-1] - 2 * I[i, j] + I[i, j+1]
        return Inxx + Inyy
    end

    # Iteramos sobre los pixeles
    for (i, j) in Iterators.product(1:size(In, 1), 1:size(In, 2))
        # Revisamos si el pixel está en el Omega
        if Omega[i, j]

            # Ecuación 7
            dLn = [
                L(In, i + 1, j) - L(In, i - 1, j),
                L(In, i, j + 1) - L(In, i, j - 1),
            ]

            # Ecuación 9
            Inx = (In[i+1, j] - In[i-1, j]) / 2
            Iny = (In[i, j+1] - In[i, j-1]) / 2
            Nn = [-Iny, Inx]
            norm_Nn = sqrt(Nn[1]^2 + Nn[2]^2 + eps)
            Nn_normalized = Nn / norm_Nn

            # Ecuación 10
            bn = dot(dLn, Nn_normalized)

            # Ecuación 11
            Inxbm = min(In[i, j] - In[i-1, j], 0)
            InxbM = max(In[i, j] - In[i-1, j], 0)
            Inxfm = min(In[i+1, j] - In[i, j], 0)
            InxfM = max(In[i+1, j] - In[i, j], 0)
            Inybm = min(In[i, j] - In[i, j-1], 0)
            InybM = max(In[i, j] - In[i, j-1], 0)
            Inyfm = min(In[i, j+1] - In[i, j], 0)
            InyfM = max(In[i, j+1] - In[i, j], 0)
            norm_grad_In_positive = sqrt(
                Inxbm^2 + InxfM^2 + Inybm^2 + InyfM^2
            )
            norm_grad_In_negative = sqrt(
                InxbM^2 + Inxfm^2 + InybM^2 + Inyfm^2
            )
            norm_grad_In = (
                bn > 0 ? norm_grad_In_positive : norm_grad_In_negative
            )

            # Ecuación 6
            Int = dot(dLn, Nn_normalized) * norm_grad_In

            # Ecuación 5
            In_siguiente[i, j] = In[i, j] + dt * Int
        end
    end
    In = copy(In_siguiente)
    return In
end

"""
structural_inpainting(
    img_path::String, 
    Omega_path::String; 
    max_iters::Int=5000, 
    dt::Float64=0.1, 
    eps::Float64=1e-7
    dilatacion::Int=0
    ) :: Array{Float64 ,2}

Función que recibe el path a una imagen y el path a un mask, en la forma de una inágen con la misma
cantidad de pixeles que la imagen original. La imagen del mask, Omega, debe ser completamente blanca
exceptuando los puntos a restaurar, que deben ser absolutamente negros. max_iters corresponde a la
cantidad de repeticiones que se desea aplicar del algoritmo presentado en el siguiente artículo:

M. Bertalmio, G. Sapiro, V. Caselles, and C. Ballester, "Image
inpainting", in Comput. Graph. (SIGGRAPH 2000), July 2000, pp.
417-424.

Nota: No se implementó la difusión anisotrópica como fue recomendado por los autores del artículo.

# Arguments
- `img_path::String`: path a la imagen a la que se le quiere realizar inpainting.
- `Omega_path::String`: path a la imagen que contiene el Omega, debe ser una imágen con las mismas.
dimensiones que la imagen original. La zona para realizar el inpainting, Ogema, debe estar en negro.
Todo el resto debe estar en blanco.
- `A::Int`: cantidad de iteraciones de inpainting (en un cíclo).
- `B::Int`: cantidad de iteraciones de difusión anisotrópica (en un cíclo).
- `max_iters::Int`: número de interaciones por realizar al algoritmo de inpainting (default: 5000).
- `dt::Float64`: velocidad de la eviolución (default: 0.1).
- `eps::Float64`: regularizador para evitar divisiones por cero (default: 1e-7)
- `dilatacion::Int`: dilatación del mask (default: 0) 

# Returns
- `Array{Float64, 2}`: array con la luminocidad de cada pixel.
"""
function structural_inpainting(
    img_path::String,
    Omega_path::String;
    A::Int=15,
    B::Int=2,
    max_iters::Int=5000,
    dt::Float64=0.1,
    eps::Float64=1e-7,
    dilatacion::Int=0,
)::Array{Float64,2}

    if max_iters < 1
        throw(ArgumentError("max_iters debe ser mayor que 1"))
    end

    # Cargamos la imágen en blanco y negro
    img = Gray.(load(img_path))

    # Transformamos la imagen en un array
    I_0 = reverse(Float64.(img), dims=1)

    # Cargamos el Omega en blanco y negro
    Omega_image = Gray.(load(Omega_path))
    # Preservamos los pixeles obscuros
    Omega = reverse(Float64.(Omega_image), dims=1) .< 0.5
    
    if size(Omega) != size(I_0)
        throw(ArgumentError(
            "Omega y img deben tener la misma cantida de pixeles."
            ))
    end

    # Aplicamos difusión anisotrópica
    println("Applying anisotropic difussion...")
    for _ in 1:800
        I_0 = anisotropic_iteration(I_0)
    end

    # Guardamos la versión anisotrópica
    img_name, _ = splitext(basename(img_path))
    I_0 = reverse(I_0, dims=1)
    save_path = joinpath(image_folder, "Anisotropic_$(img_name).jpg")
    ispath(image_folder) || mkdir(image_folder)
    save(save_path, Gray.(I_0))
    I_0 = reverse(I_0, dims=1)
    
    # Establecemos los valores de la imagen que estén en el Omega como 0.5
    I_0[Omega] .= 0.5

    # Guardamos la foto modificada
    img_name, _ = splitext(basename(img_path))
    I_0 = reverse(I_0, dims=1)
    save_path = joinpath(image_folder, "Damaged_$(img_name).jpg")
    ispath(image_folder) || mkdir(image_folder)
    save(save_path, Gray.(I_0))
    I_0 = reverse(I_0, dims=1)

    # Dilatamos el conjunto de inpainting
    for _ in dilatacion
        Omega = dilate(Omega)
    end

    # Inicializamos las image functions
    In = copy(I_0)

    # Iteramos sobre los tiempos
    println("Starting inpainting process...")
    for n in 1:max_iters
        if n % (A + B) < A
            In = inpaint_iteration(In, Omega, dt, eps)
        else
            In = anisotropic_iteration(In)
        end
        n % 10 == 0 && println("Iteración $n de $max_iters")
    end
    I_R = In
    return I_R
end

@time I_R = structural_inpainting(mickey_path, Omega_path; max_iters=100, dilatacion=1)

# Guardamos la imagen restaurada
I_R = reverse(I_R, dims=1)
save_path = joinpath(image_folder, "Restored_Mickey.png")
ispath(image_folder) || mkdir(image_folder)
save(save_path, Gray.(I_R))
