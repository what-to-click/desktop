import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:what_to_click/src/injectable.config.dart';

final sl = GetIt.instance;

@InjectableInit(preferRelativeImports: false)
void configureDependencies() => sl.init();
