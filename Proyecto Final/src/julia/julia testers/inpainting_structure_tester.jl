using ..inpainting_structure

using Images
using FileIO

main_dir = dirname(dirname(dirname(dirname(@__FILE__))))
img_dir_path = joinpath(main_dir, "Images")
restored_dir_path = joinpath(img_dir_path, "restored")
restored_dir_path = joinpath(restored_dir_path, "Structure")
mask_dir_path = joinpath(img_dir_path, "masks")
mickey_path = joinpath(img_dir_path, "barbara.jpg")
Omega_path = joinpath(mask_dir_path, "barbara_mask.jpg")

# Cargamos la imágen en blanco y negro
img = Gray.(load(mickey_path))

# Transformamos la imagen en un array
I_0 = Float64.(img)

# Cargamos el Omega en blanco y negro
Omega_image = Gray.(load(Omega_path))
# Preservamos los pixeles obscuros
Omega = Float64.(Omega_image)

@time I_R = structural_inpainting(
	I_0, Omega; dilatacion=1, anisotropic_iters=300, max_iters=1000, difussion=0.8, dt_ani=1/20, dt=0.08 # difussion=0.05
)

# Guardamos la imagen restaurada
save_path = joinpath(restored_dir_path, "Restored_barbara.jpg")
ispath(restored_dir_path) || mkdir(restored_dir_path)
save(save_path, Gray.(I_R))
println("Imagen restaurada disponible en $(save_path)")
