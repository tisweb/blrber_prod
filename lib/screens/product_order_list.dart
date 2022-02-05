import 'package:blrber/models/product.dart';
import 'package:blrber/models/product_order.dart';
import 'package:blrber/screens/order_detail.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:intl/intl.dart';

class ProductOrderList extends StatefulWidget {
  final userId;
  final displayType;
  const ProductOrderList({
    this.userId,
    this.displayType,
    key,
  }) : super(key: key);

  @override
  _ProductOrderListState createState() => _ProductOrderListState();
}

class _ProductOrderListState extends State<ProductOrderList> {
  List<ProductOrder> productOrders = [];
  List<Product> products = [];

  bool dataAvailable = false;

  @override
  void didChangeDependencies() {
    _initialDataLoad();
    super.didChangeDependencies();
  }

  _initialDataLoad() {
    productOrders = Provider.of<List<ProductOrder>>(context);
    products = Provider.of<List<Product>>(context);

    if (productOrders.length > 0 && products.length > 0) {
      switch (widget.displayType) {
        case "RO":
          productOrders = productOrders
              .where((e) => e.sellerUserId.trim() == widget.userId.trim())
              .toList();
          break;
        case "OP":
          productOrders = productOrders
              .where((e) => e.buyerUserId.trim() == widget.userId.trim())
              .toList();
          break;
        default:
      }
      if (widget.displayType == "RO") {
        productOrders = productOrders
            .where((e) => e.sellerUserId.trim() == widget.userId.trim())
            .toList();
      } else if (widget.displayType == "OP") {
        productOrders = productOrders
            .where((e) => e.buyerUserId.trim() == widget.userId.trim())
            .toList();
      }

      if (productOrders.length > 0) {
        setState(() {
          dataAvailable = true;
        });
      }
    } else {
      setState(() {
        dataAvailable = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.displayType == "RO"
            ? "Received Order List"
            : "Ordered Product List"),
      ),
      body: dataAvailable
          ? SingleChildScrollView(
              child: buildDataTable(),
              scrollDirection: Axis.horizontal,
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  Widget buildDataTable() {
    final columns = ['Select', 'Product Name', 'Order Status', 'Updated On'];

    return DataTable(
      sortAscending: false,
      showBottomBorder: true,
      sortColumnIndex: 2,
      headingRowColor: MaterialStateProperty.all<Color>(
        Colors.blueGrey[200],
      ),
      columns: getColumns(columns),
      rows: getRows(productOrders),
    );
  }

  List<DataColumn> getColumns(List<String> columns) => columns
      .map((String column) => DataColumn(
            label: Text(column),
            // onSort: onSort,
          ))
      .toList();

  List<DataRow> getRows(List<ProductOrder> productOrders) => productOrders
      .map((ProductOrder productOrder) => DataRow(
            cells: [
              DataCell(IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) {
                            return OrderDetail(
                              productOrderId: productOrder.productOrderDocId,
                              displayType: widget.displayType,
                            );
                          },
                          fullscreenDialog: true),
                    );
                  },
                  icon: Icon(Icons.arrow_right))),
              DataCell(
                Text(
                  getProductName(productOrder.productId),
                ),
              ),
              DataCell(
                Text(productOrder.orderStatus),
              ),
              DataCell(
                Text(getDateTime(productOrder.OrderCreatedAt.toDate())),
              )
            ],
          ))
      .toList();

  // List<DataRow> getRows(List<ProductOrder> productOrders) =>
  //     productOrders.map((ProductOrder productOrder) {
  //       final cells = [
  //         getProductName(productOrder.productId),
  //         productOrder.orderStatus,
  //         getDateTime(
  //           productOrder.OrderCreatedAt.toDate(),
  //         ),
  //       ];
  //       return DataRow(
  //         cells: getCells(cells),
  //       );
  //     }).toList();

  List<DataCell> getCells(List<dynamic> cells) => cells
      .map(
        (data) => DataCell(
            Text(
              data,
            ), onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) {
                  return OrderDetail(
                    displayType: widget.displayType,
                  );
                },
                fullscreenDialog: true),
          );
        }),
      )
      .toList();

  String getProductName(productId) {
    final productsOne =
        products.where((e) => e.prodDocId.trim() == productId.trim()).toList();

    return productsOne[0].prodName;
  }

  String getDateTime(DateTime dateTime) {
    return DateFormat.yMMMd().add_jm().format(dateTime).toString();
  }
}
