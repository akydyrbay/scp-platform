import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:scp_mobile_shared/models/supplier_model.dart';
import 'package:scp_mobile_shared/services/supplier_service.dart';

/// Supplier State
class SupplierState extends Equatable {
  const SupplierState({
    this.suppliers = const [],
    this.linkRequests = const [],
    this.linkedSuppliers = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  final List<SupplierModel> suppliers;
  final List<LinkRequest> linkRequests;
  final List<SupplierModel> linkedSuppliers;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  SupplierState copyWith({
    List<SupplierModel>? suppliers,
    List<LinkRequest>? linkRequests,
    List<SupplierModel>? linkedSuppliers,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return SupplierState(
      suppliers: suppliers ?? this.suppliers,
      linkRequests: linkRequests ?? this.linkRequests,
      linkedSuppliers: linkedSuppliers ?? this.linkedSuppliers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        suppliers,
        linkRequests,
        linkedSuppliers,
        isLoading,
        error,
        searchQuery,
      ];
}

/// Supplier Cubit
class SupplierCubit extends Cubit<SupplierState> {
  final SupplierService _supplierService;

  SupplierCubit({SupplierService? supplierService})
      : _supplierService = supplierService ?? SupplierService(),
        super(const SupplierState());

  /// Discover suppliers
  Future<void> discoverSuppliers({String? searchQuery}) async {
    emit(state.copyWith(isLoading: true, error: null, searchQuery: searchQuery ?? ''));

    try {
      final suppliers = await _supplierService.discoverSuppliers(
        searchQuery: searchQuery,
      );
      emit(state.copyWith(
        suppliers: suppliers,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Get linked suppliers
  Future<void> loadLinkedSuppliers() async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final linkedSuppliers = await _supplierService.getLinkedSuppliers();
      emit(state.copyWith(
        linkedSuppliers: linkedSuppliers,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Get link requests
  Future<void> loadLinkRequests() async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final linkRequests = await _supplierService.getLinkRequests();
      emit(state.copyWith(
        linkRequests: linkRequests,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Send link request
  Future<void> sendLinkRequest(String supplierId, {String? message}) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      await _supplierService.sendLinkRequest(supplierId, message: message);
      emit(state.copyWith(isLoading: false));
      // Reload link requests
      await loadLinkRequests();
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Cancel link request
  Future<void> cancelLinkRequest(String requestId) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      await _supplierService.cancelLinkRequest(requestId);
      emit(state.copyWith(isLoading: false));
      // Reload link requests
      await loadLinkRequests();
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }
}

