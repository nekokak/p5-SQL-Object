sub test_obj {
    my ($obj, $stmt, $bind, $desc) = @_;
    is $obj->as_sql, $stmt, $desc;
    is_deeply [$obj->bind], [@$bind], $desc;
}

1;
