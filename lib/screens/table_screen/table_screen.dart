import 'dart:async'; // Import for StreamSubscription
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:linkage/screens/table_screen/types.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TableScreen extends StatefulWidget {
  final String queryUuid;

  const TableScreen({super.key, required this.queryUuid});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  late Future<Map<String, dynamic>> _tableDataFuture;
  final supabase = Supabase.instance.client;

  bool? _currentSuccessStatus; // To store the success status
  bool _isCheckingInitialSuccess = true; // To manage initial loading state
  RealtimeChannel? _successSubscription;

  List<QueryColumn>? _loadedColumns;
  List<Map<String, String>>? _loadedRowsData;

  @override
  void initState() {
    super.initState();
    _tableDataFuture = _fetchTableData();
    _initializeAndSubscribeToSuccessStatus();
  }

  Future<void> _initializeAndSubscribeToSuccessStatus() async {
    // Get initial status
    try {
      final initialSuccess = await _getSuccess();
      if (mounted) {
        setState(() {
          _currentSuccessStatus = initialSuccess;
          _isCheckingInitialSuccess = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentSuccessStatus = false; // Assume failure on error
          _isCheckingInitialSuccess = false;
        });
      }
      print('Error fetching initial success status: $e');
    }

    // Subscribe to real-time updates
    _successSubscription = supabase
        .channel('public:Query:uuid=eq.${widget.queryUuid}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'Query',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'uuid',
            value: widget.queryUuid,
          ),
          callback: (payload) {
            if (mounted && payload.newRecord.containsKey('success')) {
              final newSuccessStatus = payload.newRecord['success'] as bool?;
              if (newSuccessStatus != null &&
                  newSuccessStatus != _currentSuccessStatus) {
                setState(() {
                  _currentSuccessStatus = newSuccessStatus;
                });
              }
            }
          },
        )
        .subscribe((status, [_]) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            print('Successfully subscribed to Query success updates!');
          } else if (status == RealtimeSubscribeStatus.channelError) {
            print('Error subscribing to Query success updates: $status');
          }
        });
  }

  Future<bool> _getSuccess() async {
    final response =
        await supabase
            .from('Query')
            .select('success')
            .eq('uuid', widget.queryUuid)
            .single();
    // Assuming 'success' is never null in the DB or defaults to false if it can be.
    // If 'success' can be null and that means "in progress", adjust accordingly.
    return response['success'] as bool? ?? false;
  }

  Future<Map<String, dynamic>> _fetchTableData() async {
    // ...existing code...
    try {
      final columnsResponse = await supabase
          .from('Column')
          .select('uuid, name, sort_idx')
          .eq('query_uuid', widget.queryUuid)
          .order('sort_idx', ascending: true);
      final List<QueryColumn> columns =
          (columnsResponse as List<dynamic>)
              .map(
                (data) => QueryColumn(
                  uuid: data['uuid'] as String,
                  name: data['name'] as String,
                  sortIdx: data['sort_idx'] as int,
                ),
              )
              .toList();

      if (columns.isEmpty) {
        if (mounted) {
          setState(() {
            _loadedColumns = [];
            _loadedRowsData = [];
          });
        }
        return {'columns': <QueryColumn>[], 'rows': <Map<String, String>>[]};
      }
      final recordsResponse = await supabase
          .from('Record')
          .select('uuid, sort_idx')
          .eq('query_uuid', widget.queryUuid)
          .order('sort_idx', ascending: true);

      final List<QueryRecord> records =
          (recordsResponse as List<dynamic>)
              .map(
                (data) => QueryRecord(
                  uuid: data['uuid'] as String,
                  sortIdx: data['sort_idx'] as int,
                ),
              )
              .toList();

      if (records.isEmpty) {
        if (mounted) {
          setState(() {
            _loadedColumns = columns;
            _loadedRowsData = [];
          });
        }
        return {'columns': columns, 'rows': <Map<String, String>>[]};
      }

      final List<String> recordUuids = records.map((r) => r.uuid).toList();
      final datapointsResponse = await supabase
          .from('Datapoint')
          .select('uuid, column_id, record_id, data')
          .inFilter('record_id', recordUuids);

      final List<Datapoint> allDatapoints =
          (datapointsResponse as List<dynamic>)
              .map(
                (data) => Datapoint(
                  uuid: data['uuid'] as String,
                  columnId: data['column_id'] as String,
                  recordId: data['record_id'] as String,
                  data: data['data'] as String,
                ),
              )
              .toList();

      List<Map<String, String>> processedRows = [];
      for (var record in records) {
        Map<String, String> rowData = {};
        for (var datapoint in allDatapoints.where(
          (dp) => dp.recordId == record.uuid,
        )) {
          rowData[datapoint.columnId] = datapoint.data;
        }
        processedRows.add(rowData);
      }

      // Store loaded data for Excel export
      // Use WidgetsBinding to schedule setState after the current build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _loadedColumns = columns;
            _loadedRowsData = processedRows;
          });
        }
      });

      return {'columns': columns, 'rows': processedRows};
    } catch (e) {
      print('Error fetching table data: $e');
      if (mounted) {
        setState(() {
          // Clear loaded data on error
          _loadedColumns = null;
          _loadedRowsData = null;
        });
      }
      throw Exception('Failed to load table data: $e');
    }
  }

  @override
  void dispose() {
    _successSubscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _downloadTableAsExcel() async {
    if (_loadedColumns == null || _loadedRowsData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data available to download.')),
      );
      return;
    }

    if (_loadedColumns!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No columns to download.')));
      return;
    }

    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      // Add headers
      for (int i = 0; i < _loadedColumns!.length; i++) {
        sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = _loadedColumns![i].name;
      }

      // Add data rows
      for (int i = 0; i < _loadedRowsData!.length; i++) {
        var rowDataMap = _loadedRowsData![i];
        for (int j = 0; j < _loadedColumns!.length; j++) {
          final columnUuid = _loadedColumns![j].uuid;
          sheetObject
              .cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1))
              .value = rowDataMap[columnUuid] ?? '';
        }
      }

      // Get the directory to save the file
      Directory? directory;
      if (Platform.isAndroid) {
        directory =
            await getExternalStorageDirectory(); // Or getApplicationDocumentsDirectory();
        // For public downloads folder, more complex setup might be needed (e.g., SAF or specific permissions)
        // Using getExternalStorageDirectory for broader access if permission is granted.
      } else if (Platform.isIOS || Platform.isMacOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        // For desktop or web, different handling is needed.
        // This example focuses on mobile.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download not supported on this platform yet.'),
          ),
        );
        return;
      }

      if (directory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get download directory.')),
        );
        return;
      }

      String fileName = 'query_data_${widget.queryUuid.substring(0, 8)}.xlsx';
      String filePath = '${directory.path}/$fileName';

      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded to $filePath. Attempting to open...'),
          ),
        );
        // Attempt to open the file
        final openResult = await OpenFilex.open(filePath);
        if (openResult.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open file: ${openResult.message}'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate Excel file.')),
        );
      }
    } catch (e) {
      print('Error downloading Excel: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error downloading file: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Query Results'),
        actions: [
          if (_currentSuccessStatus == true &&
              _loadedColumns != null &&
              _loadedRowsData != null &&
              _loadedColumns!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Download as Excel',
              onPressed: _downloadTableAsExcel,
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_isCheckingInitialSuccess) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Checking query status...'),
                  SizedBox(height: 10),
                  LinearProgressIndicator(),
                ],
              ),
            );
          } else if (_currentSuccessStatus == true) {
            // If success is true, build the table
            return FutureBuilder<Map<String, dynamic>>(
              future: _tableDataFuture, // This future is already initialized
              builder: (context, tableSnapshot) {
                if (tableSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (tableSnapshot.hasError) {
                  return Center(
                    child: Text('Error loading table: ${tableSnapshot.error}'),
                  );
                } else if (!tableSnapshot.hasData ||
                    tableSnapshot.data == null) {
                  return const Center(
                    child: Text('No data found for the table.'),
                  );
                }

                final List<QueryColumn> columns =
                    tableSnapshot.data!['columns'];
                final List<Map<String, String>> rowsData =
                    tableSnapshot.data!['rows'];

                if (columns.isEmpty) {
                  return const Center(
                    child: Text('No columns defined for this query.'),
                  );
                }
                if (rowsData.isEmpty && columns.isNotEmpty) {
                  return const Center(
                    child: Text('Query successful, but no records found.'),
                  );
                }

                return SizedBox.expand(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width,
                        minHeight:
                            MediaQuery.of(context).size.height -
                            (Scaffold.of(context).appBarMaxHeight ?? 0),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
                          columns:
                              columns
                                  .map(
                                    (column) =>
                                        DataColumn(label: Text(column.name)),
                                  )
                                  .toList(),
                          rows:
                              rowsData
                                  .map(
                                    (rowDataMap) => DataRow(
                                      cells:
                                          columns
                                              .map(
                                                (column) => DataCell(
                                                  Text(
                                                    rowDataMap[column.uuid] ??
                                                        '',
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            // If success is false or null (after initial check)
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Query in Progress'),
                  SizedBox(height: 10),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.75,
                    child: LinearProgressIndicator(),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
