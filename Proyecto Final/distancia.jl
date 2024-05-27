using Images

image_folder = "Proyecto Final/Images"
mickey_path = joinpath(image_folder, "Mickey.jpg")
mickey_restord_path = joinpath(image_folder, "Restored_Mickey.png")
damaged_mickey_path = joinpath(image_folder, "Damaged_Mickey.jpg")


# Cargamos la imágen en blanco y negro
mickey_img = Gray.(load(mickey_path))
# Transformamos la imagen en un array
mickey_array = reverse(Float64.(mickey_img), dims=1)

# Cargamos la imágen en blanco y negro
restored_mickey_img = Gray.(load(mickey_restord_path))
# Transformamos la imagen en un array
restored_mickey_array = reverse(Float64.(restored_mickey_img), dims=1)

# Cargamos la imágen en blanco y negro
damaged_mickey_img = Gray.(load(damaged_mickey_path))
# Transformamos la imagen en un array
damaged_mickey_array = reverse(Float64.(damaged_mickey_img), dims=1)

restoredVoriginal = assess_ssim(restored_mickey_array, mickey_array)
damagedVoriginal = assess_ssim(damaged_mickey_array, mickey_array)
damagedVrestored = assess_ssim(damaged_mickey_array, restored_mickey_array)

errores = [restoredVoriginal, damagedVoriginal, damagedVrestored]
mensaje = ["Restaurada - original", "dañada - original", "dañada - restaurada"]

for (error, mensaje) in zip(errores,mensaje)
    println("$mensaje: $(error * 100)")
end