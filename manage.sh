RED='\033[37;0;31m'
GREEN='\033[0;32;5;4m'
BLUE='\033[0;34m'
DEFAULT='\033[0m'
f=1
while f=1
do 
echo -e "\n${RED}Настройка пользователей VPN\nВыберите действие${DEFAULT}
${GREEN}                               ${DEFAULT}
${BLUE}1 - Список пользователей       \033[0;32;5m|${DEFAULT}
${BLUE}2 - Добавить пользователя      \033[0;32;5m|${DEFAULT}
${BLUE}3 - Удалить пользователя       \033[0;32;5m|${DEFAULT}
${BLUE}4 - Заблокировать пользователя \033[0;32;5m|${DEFAULT}
${BLUE}5 - Разблокировать пользователя\033[0;32;5m|${DEFAULT}

${BLUE}6 - Переустановка сертификатов\033[0;32;5m|${DEFAULT}

${BLUE}7 - Выйти из программы${DEFAULT}         \033[0;32;5m|${DEFAULT}
${GREEN}                               |${DEFAULT}"
read value
case "$value" in
1) echo -e "${RED}Список пользователей:${DEFAULT}"
 cat /etc/ocserv/ocpasswd;;

2) echo -e "${RED}Добавление пользователя${DEFAULT}\nВведите имя пользователя и пароль"
read username
ocpasswd -c /etc/ocserv/ocpasswd $username
echo -e "${GREEN} Пользователь добавлен${DEFAULT}";;

3) echo -e "${RED}Удаление пользователя${DEFAULT}\nВведите имя пользователя"
read username 
ocpasswd -c /etc/ocserv/ocpasswd -d $username
echo -e "${GREEN} Пользователь удалён${DEFAULT}";;

4) echo -e "${RED}Блокировка пользователя${DEFAULT}\nВведите имя пользователя"
read username
ocpasswd -c /etc/ocserv/ocpasswd -l $username
echo -e "${GREEN} Пользователь заблокирован${DEFAULT}";;

5) echo -e "${RED}Разблокировка пользователя${DEFAULT}\nВведите имя пользователя"
read username
ocpasswd -c /etc/ocserv/ocpasswd -u $username
echo -e "${GREEN} Пользователь разблокирован${DEFAULT}";;

6) /etc/ocserv/ocserv-install.sh cert;;

7)echo -e "${GREEN} Выход из программы${DEFAULT}"
exit;;
esac
done
