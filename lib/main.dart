import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'services/api_service.dart';
import 'models/producto.dart';

void main() {
  runApp(ProductosApp());
}

class ProductosApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Productos API',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ProductosScreen(),
    );
  }
}

class ProductosScreen extends HookWidget {
  final ApiService apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    // Estado que contiene la lista de productos
    final productos = useState<List<Producto>>([]);
    // Estado para manejar la carga
    final isLoading = useState<bool>(true);
    // Estado para manejar errores
    final hasError = useState<bool>(false);

    // Obtener productos de la API al iniciar
    useEffect(() {
      apiService.getProductos().then((value) {
        productos.value = value;
        isLoading.value = false; // Desactiva la carga cuando los datos se carguen
      }).catchError((error) {
        print(error);
        hasError.value = true; // Activa el estado de error si ocurre un problema
        isLoading.value = false;
      });
      return;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Productos'),
      ),
      body: isLoading.value
          ? Center(child: CircularProgressIndicator())
          : hasError.value
              ? Center(child: Text('Error al cargar productos'))
              : ListView.builder(
                  itemCount: productos.value.length,
                  itemBuilder: (context, index) {
                    final producto = productos.value[index];
                    return ListTile(
                      title: Text(producto.nombre),
                      subtitle: Text(producto.descripcion),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("\$${producto.precio}"), // Precio del producto
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              _showEditDialog(context, producto, index, productos);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _confirmDelete(context, producto, index, productos);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newProducto = await showDialog<Producto>(
            context: context,
            builder: (context) {
              return AgregarProductoDialog();
            },
          );

          if (newProducto != null) {
            apiService.addProducto(newProducto).then((addedProducto) {
              productos.value = [...productos.value, addedProducto];
            });
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

// Método para mostrar el diálogo de edición
  void _showEditDialog(BuildContext context, Producto producto, int index, ValueNotifier<List<Producto>> productos) async {
    final editedProducto = await showDialog<Producto>(
      context: context,
      builder: (context) {
        return EditarProductoDialog(producto: producto);
      },
    );

    if (editedProducto != null) {
      apiService.updateProducto(producto.id, editedProducto).then((updatedProducto) {
        productos.value = List.from(productos.value)..[index] = updatedProducto;
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el producto')),
        );
      });
    }
  }

  // Método para confirmar la eliminación del producto
  void _confirmDelete(BuildContext context, Producto producto, int index, ValueNotifier<List<Producto>> productos) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Eliminar Producto'),
          content: Text('¿Estás seguro de que deseas eliminar ${producto.nombre}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                apiService.deleteProducto(producto.id).then((_) {
                  productos.value = List.from(productos.value)..removeAt(index);
                  Navigator.of(context).pop(); // Cierra el diálogo después de eliminar
                }).catchError((error) {
                  Navigator.of(context).pop(); // Cierra el diálogo si hay error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar el producto')),
                  );
                });
              },
              child: Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
  }


class AgregarProductoDialog extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final nombreController = useTextEditingController();
    final descripcionController = useTextEditingController();
    final precioController = useTextEditingController();

    return AlertDialog(
      title: Text('Agregar Producto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nombreController,
            decoration: InputDecoration(labelText: 'Nombre'),
          ),
          TextField(
            controller: descripcionController,
            decoration: InputDecoration(labelText: 'Descripción'),
          ),
          TextField(
            controller: precioController,
            decoration: InputDecoration(labelText: 'Precio'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            final newProducto = Producto(
              id: 0,
              nombre: nombreController.text,
              descripcion: descripcionController.text,
              precio: precioController.text,
            );
            Navigator.of(context).pop(newProducto);
          },
          child: Text('Agregar'),
        ),
      ],
    );
  }
}


class EditarProductoDialog extends HookWidget {
  final Producto producto;

  EditarProductoDialog({required this.producto});

  @override
  Widget build(BuildContext context) {
    final nombreController = useTextEditingController(text: producto.nombre);
    final descripcionController = useTextEditingController(text: producto.descripcion);
    final precioController = useTextEditingController(text: producto.precio.toString());

    return AlertDialog(
      title: Text('Editar Producto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nombreController,
            decoration: InputDecoration(labelText: 'Nombre'),
          ),
          TextField(
            controller: descripcionController,
            decoration: InputDecoration(labelText: 'Descripción'),
          ),
          TextField(
            controller: precioController,
            decoration: InputDecoration(labelText: 'Precio'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            final updatedProducto = Producto(
              id: producto.id,
              nombre: nombreController.text,
              descripcion: descripcionController.text,
              precio: precioController.text,  // Convertir a int
            );
            Navigator.of(context).pop(updatedProducto);
          },
          child: Text('Guardar'),
        ),
      ],
    );
  }
}
