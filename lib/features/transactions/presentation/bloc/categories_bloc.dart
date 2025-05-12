import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/features/transactions/domain/usecases/create_category_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/get_categories_usecase.dart';
import 'package:monie/features/transactions/presentation/bloc/categories_event.dart';
import 'package:monie/features/transactions/presentation/bloc/categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final GetCategoriesUseCase getCategoriesUseCase;
  final CreateCategoryUseCase createCategoryUseCase;

  CategoriesBloc({
    required this.getCategoriesUseCase,
    required this.createCategoryUseCase,
  }) : super(CategoriesInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<CreateCategory>(_onCreateCategory);
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(CategoriesLoading());

    final result = await getCategoriesUseCase(isIncome: event.isIncome);

    result.fold(
      (failure) {
        emit(CategoriesError(failure.message));
      },
      (categories) {
        emit(CategoriesLoaded(categories));
      },
    );
  }

  Future<void> _onCreateCategory(
    CreateCategory event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(CategoriesLoading());

    final params = CreateCategoryParams(
      name: event.name,
      icon: event.icon,
      color: event.color,
      isIncome: event.isIncome,
    );

    final result = await createCategoryUseCase(params);

    result.fold(
      (failure) {
        emit(CategoriesError(failure.message));
      },
      (category) {
        emit(CategoryCreated(category));
        // Reload all categories to include the new one
        add(LoadCategories(isIncome: event.isIncome));
      },
    );
  }
}
