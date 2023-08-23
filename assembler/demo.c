
int main(void)
{
    
    int x[4] = { -20 , 20 , -20 , 20};
    int c[4] = { -1 , 12 , 9 , 62};

    int y = 0;

    for (int i = 0; i < 4; i++)
    {
        y = y + x[i] * c[i];
    }
    

    return y;
}