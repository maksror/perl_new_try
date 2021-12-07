package MysqlConnect;

use DBI;
use Config::General;
use File::Basename;
use Modern::Perl;

# Подключение к БД
# Входные данные: нет
# Выходные данные:
#   Успешное подключение: линка с mysql подключением
sub create_connect {
	my $dir_name = dirname(__FILE__);
	# Загружаем конфиг с атрибутами подключения к БД
	my %config = Config::General->new(
	    -ConfigFile      => "$dir_name/config.cfg",
	    -InterPolateVars => 1,
	)->getall;

    my $db_link = DBI->connect(
        "DBI:mysql:database=$config{DB};",
        $config{USER},
        $config{PASS},
        {
            'RaiseError'        => 0,
            'mysql_enable_utf8' => 1,
        },
    ) or die $DBI::errstr;

    # Если всё хорошо, то возвращаем линку
    return $db_link;
}

1;

